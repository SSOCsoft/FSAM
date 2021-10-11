Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
Pragma Restrictions( No_Implementation_Pragmas               );

With
System,
Ada.Streams,
Ada.IO_Exceptions,
Ada.Unchecked_Conversion;

Package FITS with Pure, SPARK_Mode => On is

    -----------------
    --  CONSTANTS  --
    -----------------

    -- FITS 4.0 (3.1)
    --  Each FITS structure shall consist of an integral number of
    --  FITS blocks which are each 2880 bytes (23040 bits) in length.
    Block_Size_Bits  : Constant := 23_040;
    Block_Size_Bytes : Constant := Block_Size_Bits / 8; -- Assumes 8-bit Byte.
    Pragma Assert( Block_Size_Bytes = 2_880 );

    -- FITS 4.0 (3.3.1)
    --  Each 2880-byte header block contains 36 keyword records.
    Keyword_Line_Size : Constant := 80;
    Keywords_in_Block : Constant := Block_Size_Bytes / Keyword_Line_Size;
    Pragma Assert( Keywords_in_Block = 36 );

    -- IMPLEMENTATION LIMITATION.
    Maximum_Keyword_Blocks : Constant := 100; -- So, 3_600 keywords.

    -- FITS 4.0 (3.2)
    --  The header blocks shall contain only the restricted set of ASCII text
    --  characters, decimal 32 through 126 (hexadecimal 20 through 7E).
    Header_Character_First : Constant Character := Character'Val(  32 );
    Header_Character_Last  : Constant Character := Character'Val( 126 );
    Subtype Header_Character is Character range Header_Character_First..Header_Character_Last
      with  Static_Predicate => Header_Character >= Header_Character_First and
                                Header_Character <= Header_Character_Last;
    Subtype Record_String is String
      with Dynamic_Predicate =>
        Record_String'Length <= 80 and
        (for all Ch of Record_String => Ch in Header_Character);

    Subtype KW_String is Record_String
      with Dynamic_Predicate =>
        KW_String'Length <= 8 and
        (if KW_String'Length in 1..8 then
         -- If there is a SPACE in the keword, no successive character may
         -- contain a non-SPACE character; this is equivelant to FOR ALL x in
         -- range 1..7, if the next character is not a space, neither is x.
           (for all I in KW_String'First..Positive'Pred(KW_String'Last)
                => (if KW_String(Positive'Succ(I)) /= ' ' then KW_String(I) /= ' ')
         )) and
      (for all Ch of KW_String => Ch in Header_Character);

    Checksum_Character_First : Constant Character := Character'Val( 16#30# );
    Checksum_Character_Last  : Constant Character := Character'Val( 16#72# );
    Subtype Checksum_Character is Header_Character
      range Checksum_Character_First..Checksum_Character_Last;


    subtype Digit is Header_Character
      with Static_Predicate => Digit in '0'..'9';


    Maximum_Axis_Count   : Constant := 999;
    Maximum_Axis_Value   : Constant := 2**31 - 1; --Positive'Last;


    -------------------
    --  SIMPLE TYPES --
    -------------------

    Type Unsigned_64 is mod 2**64			with Size => 64;
    Type Integer_64  is range -(2**63)..(2**63)-1	with Size => 64;

    Type Element_Type is
      (
       ET_Float_64, 	-- -64 	IEEE 64-bit floating point values
       ET_Float_32,	-- -32 	IEEE 32-bit floating point values
       ET_Unsigned_8,	--  8 	ASCII characters or 8-bit unsigned integers
       ET_Signed_16,	--  16 	16-bit, twos complement signed integers
       ET_Signed_32	--  32 	32-bit, twos complement signed integers
      );

    For Element_Type use
      (
       ET_Float_64	=> -64,
       ET_Float_32	=> -32,
       ET_Unsigned_8	=>   8,
       ET_Signed_16	=>  16,
       ET_Signed_32	=>  32
      );

    Type Element(<>) is private;



    Type Axis_Count is range 0..Maximum_Axis_Count with Size => 10;
    Type Axis_Value is range 1..Maximum_Axis_Value with Size => 32;
    Type Offset_64 is mod 2**64 with size => 64;


    --Type Axis_Range is range 1..2**32 with Size => 32;
    Type Axis_Dimensions is Array (Axis_Count range <>) of Axis_Value
      with Default_Component_Value => 1; --, TYPE_INVARIANT => true;
    Subtype Primary_Data_Array is Axis_Dimensions(1..999);
    Subtype Random_Groups_Data is Axis_Dimensions(1..998);


    Function Flatten( Item : Axis_Dimensions ) return Offset_64;
    Function EF( Item : FITS.Axis_Dimensions ) return Offset_64;

    -- FITS 4.0 (3.3.2)
    --  The individual data values shall be stored in big-endian byte order
    --  such that the byte containing the most significant bits of the
    --  value appears first in the FITS file, followed by the remaining
    --  bytes, if any, in decreasing order of significance.
--      Type

    ------------------
    --  EXCEPTIONS  --
    ------------------

--      -- Will be raised when an HDU contains an invalid character.
--      Data_Error   : Exception renames Ada.IO_Exceptions.Data_Error;
--
--      --
--      Layout_Error : Exception renames Ada.IO_Exceptions.Layout_Error;

--      Function Validate_String(Input      : String) return Boolean is
--        (for all Ch of Input => Ch in Header_Character);
--
--      Function  Validate_String(Input      : String;
--                                Is_Space   : Boolean
--                              ) return Boolean is
--        (if Is_Space then (for all C of Input => C = ' ')
--         elsif Input'Length = 0 then True
--         elsif Input(Input'First) = ' ' then
--               Validate_String(Input, True)
--         else
--             Validate_String(
--                             Input(Positive'Succ(Input'First)..Input'Last),
--                             False
--                            )
--        )
--  ;
--  --      with Post => Validate_String'Result =
--  --            (if Input'Length > 1 then
--  --               (For I in Positive range Positive'Succ(Input'First)..Input'Last
--  --                         => (if Input(Positive'Pred(I)) = ' ' then Input(I) = ' ')
--  --            ) else True);
--
--
--      Function Validate_String(Input      : String;
--                               Max_Length : Positive
--                              ) return Boolean is
--        (Input'Length <= Max_Length
--         and Validate_String(Input, False)
--         and Validate_String(Input));


Private



--      Package Internals with SPARK_Mode => Off, Convention => Fortran is
--          Generic
--              Type Object;
--          Package Ref is
--              Type Element( Item : not null access Object ) is null record
--                with Implicit_Dereference => Item;
--          End Ref;
--
--
--
--          Type Unsigned_8	is range 0..2**08-1
--            with Size =>  8;
--          Type Signed_16	is range -(2**15)..2**15-1
--            with Size => 16;
--          Type Signed_32	is range -(2**31)..2**31-1
--            with Size => 32;
--          Type Float_32	is range 0..2**08-1
--            with Size => 32;
--          Type Float_64	is range 0..2**08-1
--            with Size => 64;
--
--          Package D_08 is new Ref( Unsigned_8 );
--          Package D_16 is new Ref( Signed_16 );
--          Package D_32 is new Ref( Signed_32 );
--          Package F_32 is new Ref( Float_32 );
--          Package F_64 is new Ref( Float_64 );
--
--          Type RE
--            (
--             Style : Element_Type;
--             ED08  : D_08.Element;
--             ED16  : D_16.Element;
--             ED32  : D_32.Element;
--             EF32  : F_32.Element;
--             EF64  : F_64.Element
--            ) is record
--              null;
--              end record
--              with Implicit_Dereference =>
--                (case RE.Style is
--                   When ET_Unsigned_8	=> ED08,
--                   When ET_Signed_16	=> ED16,
--                   When ET_Signed_32	=> ED32,
--                   When ET_Float_32	=> EF32,
--                   When ET_Float_64	=> EF64
--                );
--
--      End Internals;




    Type stub is Null Record;
    Type Element( Style : Element_Type ) is record
	Case Style is
	    When ET_Unsigned_8	=>  U8  : stub; -- Interfaces.Unsigned_8 := 0;
	    When ET_Signed_16	=>  S16 : stub; -- Interfaces.Integer_16 := 0;
	    When ET_Signed_32	=>  S32 : stub; -- Interfaces.Integer_32 := 0;
	    When ET_Float_32	=>  F32 : stub; -- Interfaces.IEEE_Float_32 := 0.0;
	    When ET_Float_64	=>  F64 : stub; -- Interfaces.IEEE_Float_64 := 0.0;
	end case;
    end record;
--      with Bit_Order => System.High_Order_First, Unchecked_Union => True;
--
--
--      For Element use record
--  	U8  at 0 range 0..7;
--  	S16 at 0 range 0..15;
--  	S32 at 0 range 0..31;
--  	F32 at 0 range 0..31;
--  	F64 at 0 range 0..63;
--      end record;



--         ET_Signed_16,	--  16 	16-bit, twos complement signed integers
--         ET_Signed_32,	--  32 	32-bit, twos complement signed integers
--         ET_Float_32,	-- -32 	IEEE 32-bit floating point values
--         ET_Float_64 	-- -64 	IEEE 64-bit floating point values
--      Function Flatten( Item : Axis_Dimensions ) return Natural is
--        (case Item'Length is
--  	   when 0 => 1,
--  	   when 1 => Item( Item'First ),
--  	   when 2 => Item( Item'First ) * Item( Item'Last ),
--  	   when others =>
--  	     Flatten( Item(Item'First..Item'Last/2) ) *
--  	     Flatten( Item(Axis_Count'Succ(Item'Last/2)..Item'Last) )
--        );
End FITS;
