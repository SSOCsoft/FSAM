Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
--Pragma Restrictions( No_Implementation_Pragmas               );

With
FITS.Utils,
Ada.Characters.Handling,
Ada.Strings.Maps.Constants;

Package Body FITS.Types with SPARK_Mode => On is

    -----------------
    --  V A L U E  --
    -----------------

    Function Value( Object : Integer_String ) return Integer
      renames FITS.Types.Integer'Value;
    Function Value( Object : Real_String ) return Real
      renames FITS.Types.Real'Value;

    ---------------
    --  M A K E  --
    ---------------
    Function Make( Re, Im : Integer ) return Complex_Integer is
      (Real => Re, Imaginary => Im) with Inline;
    Function Make( Re, Im : Real    ) return Complex_Real is
      (Real => Re, Imaginary => Im) with Inline;

    Generic
        Type Component(<>) is private;
        Object    : String;
        Separator : Character:= ',';
        with Function Value(Input: String) return Component is <>;
    Package Make_Components is

        -- First we get the trimmed image; this must be "(//###//,//###//)".
        Trimmed_Image  : Complex_Integer_String renames FITS.Utils.Trim(Object);
        -- Then we get the internal range.
        Subtype Internals is Positive range
          Positive'Succ(Trimmed_Image'First)..Positive'Pred(Trimmed_Image'Last);
        -- Then we get the comma's position.
        Index          : Natural renames FITS.Utils.Index
          ( Trimmed_Image(Internals), Separator );
        -- From which we split the internal string in two.
        Subtype L_Range is Positive range Internals'First..Positive'Pred(Index);
        Subtype R_Range is Positive range Positive'Succ(Index)..Internals'Last;
        -- And THESE are the component portions.
        Real      : Component renames Value( Trimmed_Image(L_Range) );
        Imaginary : Component renames Value( Trimmed_Image(R_Range) );
    end Make_Components;

    Generic
        Type X(<>) is private;
        Type Y is new X;
    Function From_Subtype( Object : Y ) return X;
    Function From_Subtype( Object : Y ) return X is
        ( X(Object) );


    ------------------
    --  GET STRING  --
    ------------------

    Function Get_String( S : String ) return String is (S);
    Function Get_String( A : System.Address; L : Natural ) return String is
        Subtype Index is Positive range 1..L;
        Subtype Base_String is String(Index);
        Result : Base_String
          with Import, Address => A;
    Begin
        Return Result;
    End Get_String;

    -------------------
    --  TUPLE STRING --
    -------------------

    Generic
        Type Item(<>) is private;
        with Function "+"(Object : Item) return String;
    Function Tuple_String(Component_1, Component_2 : Item) return String
    with Inline;
    Function Tuple_String(Component_1, Component_2 : Item) return String is
      ( '(' & (+Component_1) & ", " & (+Component_2) & ')');

    --------------------
    --  Parse Complex --
    --------------------

    Generic
        Type Component          is private;
        Type Complex            is private;

        with Function Value(Input : String) return Component is <>;
        with Function Make(Real, Imaginary: Component) return Complex is <>;
    Function Parse_Complex(Object : String) return Complex;
    Function Parse_Complex(Object : String) return Complex is
        Package Components is new Make_Components(
           Component => Component,
           Object    => Object
          );
    Begin
        Return Make(Real => Components.Real, Imaginary=> Components.Imaginary);
    End Parse_Complex;
--      Function Parse_Complex(Object : String) return Complex is
--          -- First we get the trimmed image; this must be "(//###//,//###//)".
--          Trimmed_Image  : Constant String := FITS.Utils.Trim( Object );
--          -- Then we get the internal range.
--          Subtype Internals is Positive range
--            Positive'Succ(Trimmed_Image'First)..Positive'Pred(Trimmed_Image'Last);
--          -- Then we get the comma's position.
--          Index          : Natural renames FITS.Utils.Index
--            ( Trimmed_Image(Internals), ',' );
--          -- From which we split the internal string in two.
--          Subtype L_Range is Positive range Internals'First..Positive'Pred(Index);
--          Subtype R_Range is Positive range Positive'Succ(Index)..Internals'Last;
--
--          -- And THESE are the component portions.
--          L : Component renames Value( Trimmed_Image(L_Range) );
--          R : Component renames Value( Trimmed_Image(R_Range) );
--      Begin
--          Return Make( L , R );
--      End Parse_Complex;

    -------------------
    --  CONVERSIONS  --
    -------------------

    Function "+"(Right : Integer) return Integer_String is
        ( FITS.Utils.Left_Trim( Integer'Image(Right) ) );


    Function "+"(Right : Real) return Real_String is
        F32_First : Constant := Interfaces.IEEE_Float_32'First;
        F32_Last  : Constant := Interfaces.IEEE_Float_32'Last;

        -- The D character is used to mark exponents for DOUBLE sized types.
        Function Exponent_Map(Ch : Character) return Character is
          (if Ch = 'E' then 'D' else Ch) with Inline;

        Function Map is new FITS.Utils.Do_Map( Exponent_Map );
        Value : String renames FITS.Utils.Trim(Real'Image( Right ));
    Begin
        if Right not in F32_First..F32_Last then
            Return Map( Value );
        else
            Return Value;
        end if;
    End "+";


    Function "+"(Right : Real_String) return Real is
        Function Exponent_Map(Ch : Character) return Character is
          (if Ch = 'D' then 'E' else Ch) with Inline;

        Function Map is new FITS.Utils.Do_Map( Exponent_Map );
    Begin
        Return Real'Value( Map(Right) );
    End "+";


    Function "+"(Right : Complex_Integer) return Complex_Integer_String is
        Function Imaginary_Image is new Tuple_String( FITS.Types.Integer, "+" );
    Begin
        Return Imaginary_Image(Right.Real, Right.Imaginary);
--            '(' & (+Right.Real) & ", " & (+Right.Imaginary) & ')';
    End "+";


    Function Parse_Integer_Complex is new Parse_Complex(
       Component      => FITS.Types.Integer,
       Complex        => FITS.Types.Complex_Integer
      );
    Function "+"(Right : Complex_Integer_String) return Complex_Integer is
      ( Parse_Integer_Complex(Right) );


    Function "+"(Right : Complex_Real) return Complex_Real_String is
        Function Imaginary_Image is new Tuple_String( FITS.Types.Real, "+" );
    Begin
        Return Imaginary_Image(Right.Real, Right.Imaginary);
    End "+";


    Function Parse_Real_Complex is new Parse_Complex(
       Component      => FITS.Types.Real,
       Complex        => FITS.Types.Complex_Real
      );
    Function "+"(Right : Complex_Real_String) return Complex_Real is
      ( Parse_Real_Complex(Right) );


End FITS.Types;
