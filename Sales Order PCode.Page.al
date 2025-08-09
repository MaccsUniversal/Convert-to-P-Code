pageextension 50100 "Sales Order PCode" extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addlast(navigation)
        {
            action("Convert to PCode")
            {
                Caption = 'Convert to P-Code';
                ApplicationArea = All;
                Image = Change;
                trigger OnAction()
                var
                    CheckFields: Codeunit "Check Fields PCode";
                begin
                    Rec.SetFilter("No.", Rec."No.");
                    if Rec.FindFirst() then
                        CheckFields.Run(Rec);
                end;
            }
        }

        addlast(Category_Process)
        {
            actionref(PCodePromoted; "Convert to PCode")
            {
            }
        }
    }

    var
        myInt: Integer;
}