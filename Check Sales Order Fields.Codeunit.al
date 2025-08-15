codeunit 50100 "Check Fields PCode"
{
    TableNo = "Sales Header";
    trigger OnRun()
    begin
        Index := 1;
        CheckSaleHeaderFields(Rec);
        if not GetItemBinCodes(Rec) then
            exit;
        UpdateItemNoArray();
        CreateMovement(MovementWrkshLines);
        RegisterActivity();
        //Create Whse Shipment Doc, Register picks, ship and invoice sales order.
        //Positively adjust whse Item Journal.
    end;

    var
        MovementWrkshLines: Record "Whse. Worksheet Line";
        RegisterMovement: Codeunit "Register Movement PCode";
        CreateItem: Codeunit "Create PCode Item";
        LineNo: Integer;
        ItemNoArray: array[100] of Code[20];
        FromBinCodeArray: array[100] of Code[20];
        QtyArray: array[100] of Decimal;
        Index: Integer;
        RetreievedBinCodes: Boolean;

    local procedure UpdateItemNoArray()
    var
        i: Integer;
        ProposedItemCode: Code[20];
    begin
        for i := 1 to Index do begin
            if ItemNoArray[i] = '' then
                continue;
            ProposedItemCode := ItemNoArray[i] + 'P';
            if not DoesExist(ProposedItemCode, i) then begin
                CreatePCodeItem(ItemNoArray[i], ProposedItemCode);
                ItemNoArray[i] := ProposedItemCode;
                Commit();
            end;
        end;
    end;

    local procedure DoesExist(var ItemNo: Code[20]; Pointer: Integer): Boolean
    var
        ItemRecord: Record Item;
    begin
        if not ItemRecord.Get(ItemNo) then
            exit(false);

        ItemNoArray[Pointer] := ItemRecord."No.";
        exit(true);
    end;

    local procedure CreatePCodeItem(var FromItemNo: Code[20]; var ToItemCode: Code[20])
    var
        ItemRecord: Record Item;
        Copy: Boolean;
        TargetItemNo: Code[20];
    begin
        Copy := true;
        BindSubscription(CreateItem);
        CreateItem.SetCopyToPCode(Copy);
        CreateItem.SetCopyItemBuffer(ToItemCode, FromItemNo);
        CreateItem.Run();
        UnbindSubscription(CreateItem);
    end;

    local procedure CheckSaleHeaderFields(var SalesHeader: Record "Sales Header")
    var
        ErrorInfo: ErrorInfo;
        ShipmentMethodErrorLabel: Label 'Shipment Method Code must be PCO for Sales Order %1';
        ShippingAgentCodeErrorLabel: Label 'Shipping Agent Code must be INVOICE for Sales Order %1';
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPCodeFields(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        ErrorInfo.Title('Convert to P-Code');
        if SalesHeader."Shipment Method Code" <> 'PCO' then begin
            ErrorInfo.FieldNo(SalesHeader.FieldNo("Shipment Method Code"));
            ErrorInfo.Message(StrSubstNo(ShipmentMethodErrorLabel, SalesHeader."No."));
            Error(ErrorInfo);
        end;
        if SalesHeader."Shipping Agent Code" <> 'INVOICE' then begin
            ErrorInfo.FieldNo(SalesHeader.FieldNo("Shipping Agent Code"));
            ErrorInfo.Message(StrSubstNo(ShippingAgentCodeErrorLabel, SalesHeader."No."));
            Error(ErrorInfo);
        end;
        OnAfterCheckPCodeFields(SalesHeader);
    end;

    local procedure GetItemBinCodes(var SalesHeader: Record "Sales Header"): Boolean
    var
        SalesLine: Record "Sales Line";
        Location: Record Location;
        Ok: Boolean;
        ParameterText: Text;
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
    begin
        SalesLine.Reset();
        SalesLine.SetFilter("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Type", 'Item');
        SalesLine.FindSet();
        repeat
            Location.Get(SalesLine."Location Code");
            if not Location."Directed Put-away and Pick" then
                continue;
            SalesLine.CheckItemAvailable(SalesLine.FieldNo("Shipment Date"));
            Ok := GetBinContents(SalesLine);
            if not Ok then
                exit(Ok);
        until SalesLine.Next() <= 0;
        exit(Ok);
    end;

    local procedure GetBinContents(SalesLine: Record "Sales Line"): Boolean
    var
        BinContent: Record "Bin Content";
        TotalBaseQty: Decimal;
        ReceiptBinQty: Decimal;
        BaseQty: Decimal;
        OK: Boolean;
        ReceivingBinCode: Code[20];
    begin
        BinContent.Reset();
        BinContent.SetFilter("Item No.", SalesLine."No.");
        BinContent.FindSet();
        repeat
            case BinContent."Bin Type Code" of
                'RECEIVE':
                    begin
                        ReceiptBinQty += BinContent.CalcQtyBase();
                        ReceivingBinCode := BinContent."Bin Code";
                    end;
                'PUT AWAY':
                    begin
                        LineNo += 1000;
                        BaseQty := 0;
                        BaseQty := BinContent.CalcQtyBase();
                        TotalBaseQty += BaseQty;
                        MovementWrkshLines.Init();
                        MovementWrkshLines."Location Code" := 'EW';
                        MovementWrkshLines."Worksheet Template Name" := 'MOVEMENT';
                        MovementWrkshLines.Name := 'DEFAULT';
                        MovementWrkshLines."Line No." := LineNo;
                        MovementWrkshLines.Validate("Item No.", BinContent."Item No.");
                        ItemNoArray[Index] := BinContent."Item No.";
                        MovementWrkshLines.Validate("From Zone Code", BinContent."Zone Code");
                        MovementWrkshLines.Validate("From Bin Code", BinContent."Bin Code");
                        FromBinCodeArray[Index] := BinContent."Bin Code";
                        MovementWrkshLines.Validate("To Zone Code", 'BULK');// we can modulate this using a setup page.
                        MovementWrkshLines.Validate("To Bin Code", 'CPS');// we can modulate this using a setup page.
                        MovementWrkshLines.Validate(Quantity, BaseQty);
                        QtyArray[Index] := BaseQty;
                        MovementWrkshLines.Insert(true);
                        Index += 1;
                    end;
                'PICK', 'PUTPICK':
                    begin
                        TotalBaseQty += BinContent.CalcQtyBase();
                    end;
            end;
        until BinContent.Next <= 0;
        OK := ValidateBinQuantity(ReceiptBinQty, TotalBaseQty, SalesLine.Quantity, SalesLine."No.", ReceivingBinCode, SalesLine."Document No.");
        if not OK then
            exit(OK);

        exit(OK);
    end;

    local procedure ValidateBinQuantity(ReceiptQty: Decimal; TotalBaseQuantity: Decimal; SalesQuantity: Decimal; ItemNo: Code[20]; ReceiptBinCode: Code[20]; DocumentNo: Code[20]): Boolean
    var
        Confirmed: Boolean;
        Text000: Label 'Item %1 in receiving bin %2 will not be converted. The conversion can be made from the remaining bins. Do you want to continue?';
        Text001: Label 'There is not enough item availability in Bins to complete this conversion';
        Text002: Label 'Quantity required for item %1 on sales order %2 is in receinging bin %3. Put away the stock to a pick location to continue.';
    begin
        if (ReceiptQty >= SalesQuantity) and (TotalBaseQuantity < ReceiptQty) then
            Error(StrSubstNo(Text002, ItemNo, DocumentNo, ReceiptBinCode));
        if (TotalBaseQuantity < SalesQuantity) then
            Error(Text001);
        if ((TotalBaseQuantity >= SalesQuantity) and (ReceiptQty > 0)) then begin
            Confirmed := Confirm(StrSubstNo(Text000, ItemNo, ReceiptBinCode), true);
            if not Confirmed then
                exit(Confirmed);
        end;
        exit(true);
    end;

    local procedure CreateMovement(var WrkshLines: Record "Whse. Worksheet Line")
    var
        ParameterText: Text;
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
    begin
        MovementWrkshLines.Reset();
        MovementWrkshLines.SetRange("Worksheet Template Name", 'MOVEMENT');
        MovementWrkshLines.SetRange(Name, 'DEFAULT');
        MovementWrkshLines.FindSet();
        WhseSourceCreateDocument.SetWhseWkshLine(MovementWrkshLines);
        ParameterText := '<?xml version="1.0" standalone="yes"?><ReportParameters name="Whse.-Source - Create Document" id="7305"><Options><Field name="AssignedID" /><Field name="SortActivity">6</Field><Field name="ReservedFromStock">0</Field><Field name="BreakbulkFilter">false</Field><Field name="DoNotFillQtytoHandleReq">false</Field><Field name="PrintDoc">false</Field><Field name="ShowSummary">false</Field></Options><DataItems><DataItem name="Posted Whse. Receipt Line">VERSION(1) SORTING(Field1,Field2)</DataItem><DataItem name="Whse. Mov.-Worksheet Line">VERSION(1) SORTING(Field1,Field2,Field10,Field3)</DataItem><DataItem name="Whse. Put-away Worksheet Line">VERSION(1) SORTING(Field1,Field2,Field10,Field3)</DataItem><DataItem name="Whse. Internal Pick Line">VERSION(1) SORTING(Field1,Field2)</DataItem><DataItem name="Whse. Internal Put-away Line">VERSION(1) SORTING(Field1,Field2)</DataItem><DataItem name="Prod. Order Component">VERSION(1) SORTING(Field1,Field2,Field3,Field4)</DataItem><DataItem name="Assembly Line">VERSION(1) SORTING(Field1,Field2,Field10,Field20)</DataItem><DataItem name="Job Planning Line">VERSION(1) SORTING(Field2,Field1030)</DataItem><DataItem name="Assembly Header">VERSION(1) SORTING(Field1,Field2)</DataItem><DataItem name="AssembleToOrderJobPlanningLine">VERSION(1) SORTING(Field1,Field2,Field3)</DataItem></DataItems></ReportParameters>';
        WhseSourceCreateDocument.Execute(ParameterText);
    end;

    local procedure RegisterActivity()
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        ConversionCall: Boolean;
    begin
        BindSubscription(RegisterMovement);
        ConversionCall := true;
        RegisterMovement.SetCallingFromPCode(ConversionCall);
        RegisterMovement.Run();
        UnbindSubscription(RegisterMovement);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPCodeFields(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPCodeFields(var SalesHdr: Record "Sales Header")
    begin
    end;

}