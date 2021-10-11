Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
Pragma Restrictions( No_Implementation_Pragmas               );

Package Body FITS with Pure, SPARK_Mode => On is

    Subtype Positive_Offset is Offset_64 range 1..Maximum_Axis_Value;


    Function EF( Item : FITS.Axis_Dimensions ) return Offset_64 is
        Function Start return Axis_Count'Base is (Item'First)	with Inline;
        Function Stop  return Axis_Count'Base is (Item'Last)	with Inline;

        Function First return Axis_Value is	( Item( Start ) )
        with Inline, Pre => Item'Length > 0;
        Function Last return Axis_Value is	( Item( Stop ) )
        with Inline, Pre => Item'Length > 0;

        Function Head return Positive_Offset is ( Positive_Offset(First) )
        with Inline, Pre => Item'Length > 0;
        Function Tail return Positive_Offset is ( Positive_Offset(Last) )
        with Inline, Pre => Item'Length > 0;

    Begin
	case Item'Length is
	   when 0      => return 1;
	   when 1      => return Head;
	   when 2      => return Head * Tail;
	   when others =>
	    Declare
		Middle : Constant Axis_Count := Item'Length/2 + Start;
		Subtype Head is Axis_Count range Item'First..Middle;
		Subtype Tail is Axis_Count range Axis_Count'Succ(Middle)..Stop;
	    Begin
		Return EF(Item(Head)) * EF(Item(Tail));
	    End;
	end case;
    End EF;


    Function Flatten( Item : Axis_Dimensions ) return Offset_64 is--Interfaces.Unsigned_64 is
    Begin
        Return Result : Offset_64 := 1 do
	    For Element of Item loop
                Result := Result * Offset_64( Element );
	    End loop;
	End return;
    End Flatten;

End FITS;
