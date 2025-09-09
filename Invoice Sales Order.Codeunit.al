codeunit 50111 "Ship and Invoice Sales Order"
{
    TableNo = "Sales Header";
    EventSubscriberInstance = Manual;
    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Copy(Rec);
        Code(SalesHeader);
        Rec := SalesHeader;
    end;

    local procedure "Code"(var SalesHeader: Record "Sales Header")
    begin
        Codeunit.Run(Codeunit::"Sales-Post (Yes/No)", SalesHeader);
    end;


    procedure InvoiceFromPcodeExt(var RaiseInvoice: Boolean)
    begin
        InvoiceOrder := RaiseInvoice;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Selection Management", OnBeforeGetSalesOrderPostingSelection, '', true, true)]
    local procedure MakeSelectionOnBeforeGetSalesOrderPostingSelection(var Selection: Integer; var IsHandled: Boolean)
    begin
        if not InvoiceOrder then
            exit;

        Selection := 3;
        IsHandled := true;
    end;

    var
        InvoiceOrder: Boolean;

}