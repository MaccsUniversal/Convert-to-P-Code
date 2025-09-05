codeunit 50111 "Ship and Invoice Sales Order"
{
    TableNo = "Sales Header";
    EventSubscriberInstance = Manual;
    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        InvoiceFromPcodeExt();
        SalesHeader.Copy(Rec);
        Code(SalesHeader);
        Rec := SalesHeader;
    end;

    local procedure "Code"(var SalesHeader: Record "Sales Header")
    begin
        Codeunit.Run(Codeunit::"Sales-Post (Yes/No)", SalesHeader);
    end;


    local procedure InvoiceFromPcodeExt()
    begin
        InvoiceOrder := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Selection Management", OnBeforeGetSalesOrderPostingSelection, '', true, true)]
    local procedure MakeSelectionOnBeforeGetSalesOrderPostingSelection(var Selection: Integer; var IsHandled: Boolean)
    begin
        if not InvoiceOrder then
            exit;

        Selection := 3;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", OnBeforeConfirmSalesPost, '', true, true)]
    local procedure HideDialogOnBeforeConfirmSalesPost(var HideDialog: Boolean)
    begin
        if not InvoiceOrder then
            exit;

        HideDialog := true;
    end;

    var
        InvoiceOrder: Boolean;

}