codeunit 50102 "Create PCode Item"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        CopyItem: Codeunit "Copy Item";
    begin
        CopyItem.SetCopyItemBuffer(TempCopyItemBuffer);
        CopyItem.CopyItem(1);
    end;

    procedure SetCopyToPCode(var CopytoPCode: Boolean)
    begin
        ToPcode := CopytoPCode;
    end;

    procedure SetCopyItemBuffer(var TargetItemNo: Code[20]; var ItemNo: Code[20])
    begin
        Clear(TempCopyItemBuffer);
        TempCopyItemBuffer."Number of Copies" := 1;
        TempCopyItemBuffer."Extended Texts" := true;
        TempCopyItemBuffer."General Item Information" := true;
        TempCopyItemBuffer.Comments := true;
        TempCopyItemBuffer."Units of Measure" := true;
        TempCopyItemBuffer.Attributes := true;
        TempCopyItemBuffer."BOM Components" := true;
        TempCopyItemBuffer.Dimensions := true;
        TempCopyItemBuffer."Item References" := true;
        TempCopyItemBuffer."Item Variants" := true;
        TempCopyItemBuffer."Item Vendors" := true;
        TempCopyItemBuffer.Picture := true;
        TempCopyItemBuffer."Purchase Line Discounts" := false;
        TempCopyItemBuffer."Purchase Prices" := false;
        TempCopyItemBuffer."Sales Prices" := false;
        TempCopyItemBuffer."Sales Line Discounts" := false;
        TempCopyItemBuffer."Source Item No." := ItemNo;
        TempCopyItemBuffer."Target Item No." := TargetItemNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Item", OnAfterCopyItem, '', true, true)]
    local procedure OnOnAfterCopyItem(var TargetItem: Record Item; SourceItem: Record Item)
    begin
        if not ToPcode then
            exit;
        RemoveCosts(TargetItem);
        ToPcode := false;
    end;

    local procedure RemoveCosts(var TargetItem: Record Item)
    begin
        TargetItem."Last Direct Cost" := 0;
        TargetItem."Unit Cost" := 0;
        TargetItem."Unit Price" := 0;
        TargetItem.Modify();
    end;

    var
        ToPcode: Boolean;
        TempCopyItemBuffer: Record "Copy Item Buffer" temporary;
        SourceItem1: Record Item;
}