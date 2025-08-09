codeunit 50100 "Check Fields PCode"
{
    TableNo = "Sales Header";
    trigger OnRun()
    begin
        CheckFields(Rec);
    end;

    local procedure CheckFields(var SalesHeader: Record "Sales Header")
    var
        ErrorInfo: ErrorInfo;
        ShipmentMethodErrorLabel: Label 'Shipment Method Code must be PCO for Sales Order %1';
        ShippingAgentCodeErrorLabel: Label 'Shipping Agent Code must be INVOICE for Sales Order %1';
    begin
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
    end;

}