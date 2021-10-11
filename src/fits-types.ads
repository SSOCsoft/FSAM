Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
Pragma Restrictions( No_Implementation_Pragmas               );

--  With
--  Ada.Containers.Indefinite_Holders,
--  Ada.Containers.Bounded_Ordered_Maps;

With
Interfaces;

--Private
Package FITS.Types with Pure, SPARK_Mode => On is

--      Package String_Holder_Package is new Ada.Containers.Indefinite_Holders
--        (
--         --"="          => <>,
--         Element_Type => String
--        );
--
--      Subtype String_Holder is String_Holder_Package.Holder;

--      Package K is new Ada.Containers.Bounded_Ordered_Maps
--        (
--  --         "<"          => ,
--  --         "="          => ,
--         Key_Type     => String,
--         Element_Type => String_Holder
--        );

    --------------------------
    --  CHARACTER SUBTYPES  --
    --------------------------

    Subtype Complex is Character
      with Static_Predicate => Complex in '('|','|')'|' ';
    Subtype Float is Character
      with Static_Predicate => Float in '.'|'E'|'D';
    Subtype Logical_Character is Character
      with Static_Predicate => Logical_Character in 'T'|'F';
    Subtype Complex_Real_Character is Header_Character
      with Static_Predicate =>
        Complex_Real_Character in '+'|'-'|Digit|Float|Complex;
    Subtype Complex_Integer_Character is Complex_Real_Character
      with Static_Predicate =>
        Complex_Integer_Character not in Float;
    Subtype Real_Character is Complex_Real_Character
      with Static_Predicate => Real_Character not in Complex;
    Subtype Integer_Character is Real_Character
      with Static_Predicate => Integer_Character not in Float;


    -----------------------
    --  STRING SUBTYPES  --
    -----------------------

    Subtype Complex_Real_String is Record_String
      with Dynamic_Predicate => (TRUE);
    Subtype Complex_Integer_String is Record_String
      with Dynamic_Predicate => (TRUE);
    Subtype Real_String is Record_String
      with Dynamic_Predicate => (TRUE);
    Subtype Integer_String is Record_String
      with Dynamic_Predicate =>
        Integer_String(Integer_String'First) in Integer_Character and
        (for all I in Natural'Succ(Integer_String'First)..Integer_String'Last =>
          Integer_String(I) in Digit);


    ----------------------------------------------------------------------------
    --  LOGICAL                                                   FITS 4.2.2  --
    ----------------------------------------------------------------------------

    Type Logical is new Boolean
      with Size => Character'Size;

    Function "+"(Right : Logical) return Boolean;
    Function "+"(Right : Boolean) return Logical;
    Function "+"(Right : Logical) return Character;
    Function "+"(Right : Logical_Character) return Logical;

    ----------------------------------------------------------------------------
    --  INTEGER                                                   FITS 4.2.3  --
    ----------------------------------------------------------------------------

    Type Integer is new Interfaces.Integer_64;

    Function "+"(Right : Integer) return Integer_String;
    Function "+"(Right : Integer_String) return Integer;

    ----------------------------------------------------------------------------
    --  REAL-NUMBER                                               FITS 4.2.4  --
    ----------------------------------------------------------------------------

    Type Real is new Interfaces.IEEE_Float_64;

    Function "+"(Right : Real) return Real_String;
    Function "+"(Right : Real_String) return Real;

    ----------------------------------------------------------------------------
    --  COMPLEX INTEGER                                           FITS 4.2.5  --
    ----------------------------------------------------------------------------

    Type Complex_Integer is record
        Real, Imaginary : FITS.Types.Integer;
    end record;

    Function "+"(Right : Complex_Integer) return Complex_Integer_String;
    Function "+"(Right : Complex_Integer_String) return Complex_Integer;

    ----------------------------------------------------------------------------
    --  COMPLEX REAL                                              FITS 4.2.6  --
    ----------------------------------------------------------------------------

    Type Complex_Real is record
        Real, Imaginary : FITS.Types.Real;
    end record;

    Function "+"(Right : Complex_Real) return Complex_Real_String;
    Function "+"(Right : Complex_Real_String) return Complex_Real;



Private
    For Logical use(
       True  => Character'Pos('T'),
       False => Character'Pos('F')
      );

    ------------------
    -- CONVERSIONS  --
    ------------------
    Function Convert is new Ada.Unchecked_Conversion(
       Source => Logical,
       Target => Character
      );

    Function "+"(Right : Logical) return Boolean is
      ( Boolean(Right) );
    Function "+"(Right : Boolean) return Logical is
      ( Logical(Right) );
    Function "+"(Right : Logical) return Character is
      ( Convert(Right) );
    Function "+"(Right : Logical_Character) return Logical is
      ( +(Right = 'T') );

    Function "+"(Right : Integer_String) return Integer is
      ( Integer'Value(Right) );



End FITS.Types;
