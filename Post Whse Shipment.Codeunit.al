codeunit 50106 "Whse. Ship and Invoice"
{
    EventSubscriberInstance = Manual;
    TableNo = "Warehouse Shipment Header";
    trigger OnRun()
    begin
        GetWhseShipmentLines(Rec);
    end;

    procedure EnableEvent(var Enable: Boolean)
    begin
        EventEnabled := Enable;
    end;

    procedure GetWhseShipmentLines(var WhseShptHdr: Record "Warehouse Shipment Header")
    var
        WhseShptLine: Record "Warehouse Shipment Line";

    begin
        WhseShptLine.SetFilter("No.", WhseShptHdr."No.");
        WhseShptLine.FindSet();
        PostWhseShipmentDoc(WhseShptLine);
    end;

    local procedure PostWhseShipmentDoc(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        SubscribedEvents: Codeunit "Subscribed Events";
        HideDialog: Boolean;
    begin
        HideDialog := true;
        BindSubscription(SubscribedEvents);
        SubscribedEvents.SetConfirmShipment(HideDialog);
        Codeunit.Run(Codeunit::"Whse.-Post Shipment (Yes/No)", WarehouseShipmentLine);
        UnbindSubscription(SubscribedEvents);
    end;

    var
        EventEnabled: Boolean;
}