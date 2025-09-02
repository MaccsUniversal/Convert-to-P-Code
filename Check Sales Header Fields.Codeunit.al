codeunit 50108 "Sales Header - Check Fields"
{
    procedure CheckSaleHeaderFields(var SalesHeader: Record "Sales Header")
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPCodeFields(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPCodeFields(var SalesHdr: Record "Sales Header")
    begin
    end;
}