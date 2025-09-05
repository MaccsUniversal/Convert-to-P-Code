codeunit 50104 "Create Whse. Shpmt and Picks"
{
    TableNo = "Sales Header";
    EventSubscriberInstance = Manual;
    trigger OnRun()
    begin
        Rec.PerformManualRelease();
        CreateWhseShipment(Rec);
        CreatePickLines();
        RegisterPick();
        ShipAndInvoice();
    end;

    local procedure ShipAndInvoice()
    begin
        EnableWhseShipAndInvoiceEvents();
        RunShipAndInvoice();
    end;

    local procedure EnableWhseShipAndInvoiceEvents()
    var
        Enable: Boolean;
        WhseShipAndInvoice: Codeunit "Whse. Ship and Invoice";
    begin
        Enable := true;
        BindSubscription(WhseShipAndInvoice);
        WhseShipAndInvoice.EnableEvent(Enable);
        UnbindSubscription(WhseShipAndInvoice);
    end;

    local procedure RunShipAndInvoice()
    begin
        Codeunit.Run(Codeunit::"Whse. Ship and Invoice", WarehouseShipmentHeader);
    end;

    procedure PickAfterWhseShpmt(var PickAfterShipment: Boolean)
    begin
        CreatePickAfterWhseShpt := PickAfterShipment;
    end;

    procedure PickOnly(var CreatePick: Boolean)
    begin
        CreatePickOnly := CreatePick;
    end;

    local procedure RegisterPick()
    var
        RegisterPickActivity: Codeunit "Register Activity PCode";
        FromConversionCall: Boolean;
    begin
        FromConversionCall := true;
        RegisterPickActivity.SetCallingFromPCode(FromConversionCall);
        RegisterPickActivity.RegisterWhsePickActivHdr();
    end;

    procedure CreateWhseShptDoc(var WhseShpt: Boolean)
    begin
        CreateWhseShpt := WhseShpt;
    end;

    local procedure CreateWhseShipment(var SalesHeader: Record "Sales Header")
    var
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        if not CreateWhseShpt then
            exit;

        GetSourceDocOutbound.CreateFromSalesOrder(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Outbound", OnAfterCreateWhseShipmentHeaderFromWhseRequest, '', true, true)]
    local procedure CreatePickOnAfterCreateWhseShipmentHeaderFromWhseRequest(WhseShptHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentHeader := WhseShptHeader;
        if not CreatePickAfterWhseShpt then
            exit;

        if (WarehouseRequest.Type = WarehouseRequest.Type::Outbound) and
        (WarehouseRequest."Source Document" = WarehouseRequest."Source Document"::"Sales Order") and
        (WarehouseRequest."Source Subtype" = WarehouseRequest."Source Subtype"::"1") and
        (WarehouseRequest."Source Type" = 37)
        then begin
            WarehouseShipmentLine.Reset();
            WhseShptHeader.Reset();
            WarehouseShipmentLine.SetFilter("No.", WhseShptHeader."No.");
            WarehouseShipmentLine.FindSet();
            WhseShptHeader.SetFilter("No.", WhseShptHeader."No.");
            WhseShptHeader.FindSet();
            CreatePickLinesFromShpt(WarehouseShipmentLine, WhseShptHeader);
        end;
    end;

    local procedure CreatePickLinesFromShpt(var WhseShptLine: Record "Warehouse Shipment Line"; var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseCreatePickRep: Report "Whse.-Shipment - Create Pick";
        ReportParameters: Text;
    begin
        WhseCreatePickRep.SetWhseShipmentLine(WhseShptLine, WhseShptHeader);
        ReportParameters := '<?xml version="1.0" standalone="yes"?><ReportParameters name="Whse.-Shipment - Create Pick" id="7318"><Options><Field name="AssignedIDReq" /><Field name="SortActivity">6</Field><Field name="BreakbulkFilterReq">false</Field><Field name="DoNotFillQtytoHandleReq">false</Field><Field name="ApplyCustomSorting">false</Field><Field name="PrintDocReq">false</Field><Field name="ShowSummary">false</Field></Options><DataItems><DataItem name="Warehouse Shipment Line">VERSION(1) SORTING(Field1,Field2)</DataItem><DataItem name="Assembly Header">VERSION(1) SORTING(Field1,Field2)</DataItem><DataItem name="Assembly Line">VERSION(1) SORTING(Field1,Field2,Field3)</DataItem></DataItems></ReportParameters>';
        WhseCreatePickRep.Execute(ReportParameters);
    end;

    local procedure CreatePickLines()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if not CreatePickOnly then
            exit;

        WarehouseShipmentLine.Reset();
        WarehouseShipmentHeader.Reset();
        WarehouseShipmentLine.SetFilter("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindSet();
        WarehouseShipmentHeader.SetFilter("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentHeader.FindSet();
        CreatePickLinesFromShpt(WarehouseShipmentLine, WarehouseShipmentHeader);
    end;

    var
        CreatePickOnly: Boolean;
        CreatePickAfterWhseShpt: Boolean;
        CreateWhseShpt: Boolean;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
}