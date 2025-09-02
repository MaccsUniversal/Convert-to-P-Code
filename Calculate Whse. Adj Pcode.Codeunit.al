codeunit 50109 "Calculate Whse. Adj Pcode"
{
    EventSubscriberInstance = Manual;
    trigger OnRun()
    begin
        InitItemJournalLines();
        PostItemJnlLines();
    end;

    local procedure PostItemJnlLines()
    var
        PostItemJnlLine: Codeunit "Post Item Jnl Lines PCode";
        ConfirmShipment: Boolean;
        SubscribedEvents: Codeunit "Subscribed Events";
    begin
        ConfirmShipment := true;
        BindSubscription(PostItemJnlLine);
        BindSubscription(SubscribedEvents);
        SubscribedEvents.SetConfirmShipment(ConfirmShipment);
        PostItemJnlLine.Run(ItemJnlLines);
        UnbindSubscription(PostItemJnlLine);
        UnbindSubscription(SubscribedEvents);
    end;

    local procedure InitItemJournalLines()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.Get('ITEM');
        ItemJournalBatch.Get(ItemJournalTemplate.Name, 'PCODE');
        if ItemJnlLines.Get(ItemJournalTemplate.Name, ItemJournalBatch.Name, 0) then
            ItemJnlLines.DeleteAll();
        ItemJnlLines.Init();
        ItemJnlLines."Journal Template Name" := ItemJournalTemplate.Name;
        ItemJnlLines."Journal Batch Name" := ItemJournalBatch.Name;
        ItemJnlLines."Line No." := 0;
        ItemJnlLines.Insert();
        Commit();
        if ItemJnlLines.Get(ItemJournalTemplate.Name, ItemJournalBatch.Name, 0) then
            CalcuateWhseAdjLines();
    end;

    local procedure CalcuateWhseAdjLines()
    var
        CalcWhseAdj: Report "Calculate Whse. Adjustment";
        HideDialog: Boolean;
        Item: Record Item;
    begin
        HideDialog := true;

        CalcWhseAdj.SetHideValidationDialog(HideDialog);
        CalcWhseAdj.SetItemJnlLine(ItemJnlLines);
        CalcWhseAdj.InitializeRequest(Today(), 'Paid call Off Auto');
        CalcWhseAdj.Execute(RequestPageText);
    end;

    procedure SetRequestPageText(var ItemNo: array[100] of Code[20])
    var
        PostingDate: Date;
        DocNo: Code[20];
    begin
        ItemValues := GetItemValues(ItemNo);
        PostingDate := Today();
        DocNo := 'Paid Call Off';
        RequestPageText := '<?xml version="1.0" standalone="yes"?><ReportParameters name="Calculate Whse. Adjustment" id="7315"><Options><Field name="PostingDate"></Field><Field name="NextDocNo"></Field></Options><DataItems><DataItem name="Item">VERSION(1) SORTING(Field1) WHERE(Field1=1(' + Format(ItemValues) + '),Field67=1(EW))</DataItem><DataItem name="Integer">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>';
    end;

    local procedure GetItemValues(var ItemNo: array[100] of Code[20]): Text
    var
        i: Integer;
        ItemCounter: Integer;
        ItemList: Text;
    begin
        ItemCounter := 0;
        for i := 1 to ArrayLen(ItemNo) do begin
            if itemNo[i] = '' then
                continue;
            ItemCounter += 1;
            if ItemCounter > 1 then begin
                ItemList := ItemList + ',' + ItemNo[i];
            end else begin
                ItemList := ItemNo[i];
            end;
        end;
        exit(ConvertListToFilterFormat(ItemList))
    end;

    local procedure ConvertListToFilterFormat(var ItemList: Text) Items: Text
    begin
        if ItemList.Contains(',') then begin
            ItemList := ItemList.Replace(',', '|');
            Items := ItemList;
        end else begin
            Items := ItemList;
        end;
        exit(Items);
    end;

    var
        ItemJnlLines: Record "Item Journal Line";
        RequestPageText: Text;
        ItemValues: Text;
}