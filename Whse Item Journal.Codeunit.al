codeunit 50107 "Whse Item Journal PCode"
{
    EventSubscriberInstance = Manual;
    trigger OnRun()
    begin
        InsertWarehouseItemJournalLines();
        PostWarehouseItemJournalLines();
    end;

    procedure SetArrays(var ItemArray: array[100] of Code[20]; var BinArray: array[100] of Code[20]; var UnitOfMeasureArray: array[100] of Code[10]; var QuantityArray: array[100] of Decimal)
    begin
        CopyArray(ItemNoArray, ItemArray, 1, ArrayLen(ItemArray));
        CopyArray(BinCodeArray, BinArray, 1, ArrayLen(BinArray));
        CopyArray(UOMArray, UnitOfMeasureArray, 1, ArrayLen(UnitOfMeasureArray));
        CopyArray(QtyArray, QuantityArray, 1, ArrayLen(QuantityArray));
    end;

    local procedure InsertWarehouseItemJournalLines()
    var
        i: Integer;
        LineNo: Integer;
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJournalTemplate: Record "Warehouse Journal Template";
    begin
        WhseJournalTemplate.Get('ITEM');
        WhseJnlBatch.Get(WhseJournalTemplate.Name, 'DEFAULT', 'EW');
        WarehouseItemJnlLine.SetRange("Journal Template Name", WhseJnlBatch."Journal Template Name");
        WarehouseItemJnlLine.SetRange("Journal Batch Name", WhseJnlBatch.Name);
        WarehouseItemJnlLine.DeleteAll();
        LineNo := 10000;
        for i := 1 to ArrayLen(ItemNoArray) do begin
            if ItemNoArray[i] = '' then
                continue;
            WarehouseItemJnlLine.Init();
            WarehouseItemJnlLine."Journal Template Name" := WhseJnlBatch."Journal Template Name";
            WarehouseItemJnlLine."Journal Batch Name" := WhseJnlBatch.Name;
            WarehouseItemJnlLine."Location Code" := 'EW';
            WarehouseItemJnlLine."Line No." := LineNo;
            WarehouseItemJnlLine."Registering Date" := Today();
            WarehouseItemJnlLine."Whse. Document No." := 'POSITIVE';
            WarehouseItemJnlLine.Validate("Item No.", ItemNoArray[i]);
            WarehouseItemJnlLine.Validate(Quantity, QtyArray[i]);
            WarehouseItemJnlLine.Validate("Zone Code", GetZoneCode(BinCodeArray[i]));
            WarehouseItemJnlLine.Validate("Bin Code", BinCodeArray[i]);
            WarehouseItemJnlLine."Unit of Measure Code" := UOMArray[i];
            WarehouseItemJnlLine."Source Code" := WhseJournalTemplate."Source Code";
            WarehouseItemJnlLine."Reason Code" := WhseJnlBatch."Reason Code";
            WarehouseItemJnlLine."Registering No. Series" := WhseJnlBatch."Registering No. Series";
            WarehouseItemJnlLine."Entry Type" := WarehouseItemJnlLine."Entry Type"::"Positive Adjmt.";
            WarehouseItemJnlLine.SetUpAdjustmentBin();
            WarehouseItemJnlLine.Insert(true);
            LineNo += 10000;
        end;
        ReadyToPost := true;
        Commit();
    end;

    local procedure GetItemDescription(var ItemNo: Code[20]): Text[100]
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item.Description);
    end;

    local procedure PostWarehouseItemJournalLines()
    var
        SubscribedEvents: Codeunit "Subscribed Events";
    begin
        BindSubscription(SubscribedEvents);
        SubscribedEvents.SetPostWhseItemJnlLines(ReadyToPost);
        Codeunit.Run(Codeunit::"Whse. Jnl.-Register", WarehouseItemJnlLine);
        UnbindSubscription(SubscribedEvents);
    end;

    local procedure GetZoneCode(BinCode: Code[20]) ZoneCode: Code[20]
    var
        Bin: Record "Bin";
    begin
        Bin.SetFilter("Code", BinCode);
        Bin.FindSet();
        exit(Bin."Zone Code");
    end;

    var
        WarehouseItemJnlLine: Record "Warehouse Journal Line";
        ItemNoArray: array[100] of Code[20];
        BinCodeArray: array[100] of Code[20];
        QtyArray: array[100] of Decimal;
        UOMArray: array[100] of Code[10];
        ReadyToPost: Boolean;
}