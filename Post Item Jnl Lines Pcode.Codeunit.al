codeunit 50110 "Post Item Jnl Lines PCode"
{
    EventSubscriberInstance = Manual;
    TableNo = "Item Journal Line";
    trigger OnRun()
    begin
        PostItemJnl(Rec);
    end;

    local procedure PostItemJnl(var ItemJnlLine: Record "Item Journal Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post", ItemJnlLine);
    end;
}