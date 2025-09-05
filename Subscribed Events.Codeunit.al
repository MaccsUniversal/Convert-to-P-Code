codeunit 50105 "Subscribed Events"
{
    EventSubscriberInstance = Manual;

    procedure SetInvoiceSalesOrder(var InvoiceFromPcode: Boolean)
    begin
        Invoice := InvoiceFromPcode;
    end;

    procedure SetConfirmShipment(var Confirmshpt: Boolean)
    begin
        ConfirmShipment := Confirmshpt;
    end;

    procedure SetPostWhseItemJnlLines(var PostLines: Boolean)
    begin
        PostJnlLines := PostLines;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post", OnBeforeCode, '', true, true)]
    local procedure OnBeforeCodeItemJnlPost(var HideDialog: Boolean)
    begin
        if not ConfirmShipment then
            exit;

        HideDialog := true;
        ConfirmShipment := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", OnGetResultMessageOnBeforeShowMessage, '', true, true)]
    local procedure OnOnGetResultMessageOnBeforeShowMessage(var IsHandled: Boolean)
    begin
        if not ConfirmShipment then
            exit;

        IsHandled := true;
        ConfirmShipment := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment (Yes/No)", OnBeforeConfirmWhseShipmentPost, '', true, true)]
    local procedure OnOnBeforeConfirmWhseShipmentPost(var HideDialog: Boolean; var Invoice: Boolean; var Selection: Integer; var IsPosted: Boolean)
    begin
        if not ConfirmShipment then
            exit;

        IsPosted := false;
        HideDialog := true;
        Invoice := true;
        Selection := 2;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Act.-Register (Yes/No)", OnBeforeConfirmRegister, '', true, true)]
    local procedure OnOnBeforeConfirmRegister(var IsHandled: Boolean; var Result: Boolean)
    begin
        if not ConfirmShipment then
            exit;

        IsHandled := true;
        Result := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Source Documents", OnBeforeShowSingleWhseShptHeaderCreatedMessage, '', true, true)]
    local procedure HideWarehouseShipmentDialog(var IsHandled: Boolean)
    begin
        if not ConfirmShipment then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register", OnBeforeConfirmRegisterLines, '', true, true)]
    local procedure OnOnBeforeConfirmRegisterLines(var IsHandled: Boolean; var Result: Boolean)
    begin
        if not PostJnlLines then
            exit;
        IsHandled := true;
        Result := true;
        PostJnlLines := false;
    end;

    var
        Invoice: Boolean;
        ConfirmShipment: Boolean;
        PostJnlLines: Boolean;
}