codeunit 50101 "Register Activity PCode"
{
    EventSubscriberInstance = Manual;
    trigger OnRun()
    begin
        // RegisterWhseActivHdr();
    end;

    procedure SetCallingFromPCode(PCodeConversionCall: Boolean)
    begin
        ConversionCall := PCodeConversionCall;
    end;

    procedure RegisterWhseMoveActivHdr()
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivHeader.Reset();
        WhseActivHeader.SetFilter(Type, Format(WhseActivHeader.Type::Movement));
        WhseActivHeader.FindLast();
        WhseActivLine.Reset();
        WhseActivLine.SetFilter("No.", WhseActivHeader."No.");
        WhseActivLine.FindSet();
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Register (Yes/No)", WhseActivLine);
    end;

    procedure RegisterWhsePickActivHdr()
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivHeader.Reset();
        WhseActivHeader.SetFilter(Type, Format(WhseActivHeader.Type::Pick));
        WhseActivHeader.FindLast();
        WhseActivLine.Reset();
        WhseActivLine.SetFilter("No.", WhseActivHeader."No.");
        WhseActivLine.FindSet();
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Register (Yes/No)", WhseActivLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Act.-Register (Yes/No)", OnBeforeConfirmRegister, '', true, true)]
    local procedure ConfirmMovementRegistration(var IsHandled: Boolean; var Result: Boolean)
    begin
        if not ConversionCall then
            exit;

        IsHandled := true;
        Result := true;
        ConversionCall := false;
    end;

    var
        ConversionCall: Boolean;
}