Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
--Pragma Restrictions( No_Implementation_Pragmas               );
-- We need the WARNINGS(OFF) pragma on the representation-clause to silence the
-- GNAT compiler's INFO messages regarding non-native bit ordering.

With
System,
FITS.Checksum;

Separate (FITS.Checksum)
Function Read_Bytes( Input : Interfaces.Unsigned_32 ) return Bytes
  with SPARK_Mode => On is

    Function Swap( Input : Interfaces.Unsigned_32 ) return Bytes
      with Inline;

    Type Integer_Components is record
        A, B, C, D : Interfaces.Unsigned_8;
    end record
    with Bit_Order => System.High_Order_First;

    Pragma Warnings( OFF );
    For Integer_Components use record
        A at 0 range  0..7;
        B at 0 range  8..15;
        C at 0 range 16..23;
        D at 0 range 24..31;
    end record;
    Pragma Warnings(ON);

    Use_Default_Bit_Order : Constant Boolean :=
      System."="( System.Default_Bit_Order, System.High_Order_First );

    Function Convert is new Ada.Unchecked_Conversion(
       Source => Interfaces.Unsigned_32,
       Target => Integer_Components
      );

    Function Convert is new Ada.Unchecked_Conversion(
       Source => Interfaces.Unsigned_32,
       Target => Bytes
      );

    Function Swap( Input : Interfaces.Unsigned_32 ) return Bytes is
        Result : Integer_Components renames Convert(Input);
    Begin
        Return ( Result.A, Result.B, Result.C, Result.D );
    End Swap;


Begin
    Return (if Use_Default_Bit_Order
            then Convert( Input )
            else Swap   ( Input )
           );
End Read_Bytes;
