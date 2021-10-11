Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
Pragma Restrictions( No_Implementation_Pragmas               );

With
FITS.Types;

Package Body FITS.Checksum with SPARK_Mode => On is

    Function Convert is new Ada.Unchecked_Conversion(
       Source => Object,
       Target => Checksum_String
      );

    Function As_String(Item : Object) return Record_String is
      ( Convert(Item) );

    Type Bytes is Array(Index_A) of Unsigned_8 with Convention => Fortran;
    Function Read_Bytes( Input : Interfaces.Unsigned_32 ) return Bytes
      with Inline;

    Function Normalize( Item : Object ) return Object
      with Inline, Post => Readable(Normalize'Result);


    Function Init( X : Interfaces.Unsigned_32 ) return Object
      --with Refined_Post => Readable(Init'Result) is
        is
        -- FITS J.2 (1)
        -- One's complement the input 32-bit checksum.
        Complement : Constant Interfaces.Unsigned_32:= not X;

        -- FITS J.2 (2)
        -- Interpret the 32-bit value as a sequence of unsigned 8-bit bytes.
        -- Generate the sequence such that all compnents are 1/4th the original
        -- with the first containing the excess of the division.
        Function Populate(Input: Bytes) Return Object with Inline;

        -- FITS J.2 (3)
        -- Add 48 ($30; ASCII value of '0') to each element.
        Function "+"( Item : Object ) return Object with Inline;

        -- FITS J.2 (4)
        Function Make_Readable( Item : Object ) return Object
          with Inline, Post => Readable(Make_Readable'Result);

        -- FITS J.2 (5)
        -- Shift all 16 characters one place to the right, shifting D4 to the
        -- first location. (This compensates for the checksum's location.)
        Function "-"( Item : Object ) return Object
          with Inline, Pre => Readable(Item), Post => Readable("-"'Result);

        Function Populate(Input: Bytes) Return Object is
            Denominator : Constant := 4;

            Div_A   : Interfaces.Unsigned_8 renames "/" (Input(A), Denominator);
            Div_B   : Interfaces.Unsigned_8 renames "/" (Input(B), Denominator);
            Div_C   : Interfaces.Unsigned_8 renames "/" (Input(C), Denominator);
            Div_D   : Interfaces.Unsigned_8 renames "/" (Input(D), Denominator);

            Rem_A   : Interfaces.Unsigned_8 renames "rem"(Input(A),Denominator);
            Rem_B   : Interfaces.Unsigned_8 renames "rem"(Input(B),Denominator);
            Rem_C   : Interfaces.Unsigned_8 renames "rem"(Input(C),Denominator);
            Rem_D   : Interfaces.Unsigned_8 renames "rem"(Input(D),Denominator);
        Begin
            Return Result : Constant Object :=
              (A => (1 => Div_A+Rem_A, others => Div_A),
               B => (1 => Div_B+Rem_B, others => Div_B),
               C => (1 => Div_C+Rem_C, others => Div_C),
               D => (1 => Div_D+Rem_D, others => Div_D)
              );
        end Populate;

        Function "+"( Item : Object ) return Object is
            Offset         : Constant := Character'Pos('0');	-- FITS J.2 (3)
        begin
            Return Result  : Object := Item do
                For Object of Result loop
                    Object:= Object + Offset;
                end loop;
            end return;
        end "+";


        Function Make_Readable( Item : Object ) return Object --is
          renames Normalize;
--              Procedure Do_Pair(A, B : in out Interfaces.Unsigned_8)
--                with Inline, Post => Readable(A) and Readable(B);
--              Procedure Do_Index_A( X : in out Object; Index : Index_A )
--                with Inline, Post => (For all B in Index_B => Readable(X(Index,B)) );
--
--              Procedure Do_Pair(A, B : in out Interfaces.Unsigned_8) is
--                  Use Interfaces;
--                  Function Inc(X : Unsigned_8) return Unsigned_8
--                               renames Unsigned_8'Succ;
--                  Function Dec(X : Unsigned_8) return Unsigned_8
--                               renames Unsigned_8'Pred;
--              Begin
--                  loop
--                      Exit when Readable(A) and Readable(B);
--                      A:= Inc(A);
--                      B:= Dec(B);
--                  end loop;
--                  Pragma Assert( Readable(A) and Readable(B) );
--              End Do_Pair;
--
--              Procedure Do_Index_A( X : in out Object; Index : Index_A ) is
--              Begin
--                  Do_Pair( X(Index,1), X(Index,2) );
--                  Do_Pair( X(Index,3), X(Index,4) );
--              End Do_Index_A;
--
--          Begin
--              Return Result : Object := Item do
--                  For Index in Result'Range(1) loop
--                      Do_Index_A( Index => Index, X => Result );
--                  end loop;
--                  --Pragma Assert( for all X of Result => Readable(X) );
--                  Pragma Assert( Readable(Result) );
--              end return;
--          End Make_Readable;

        Function "-"( Item : Object ) return Object is
            Last        : Constant := 16;
            Penultiment : Constant := Last-1;
            Type Byte_Sequence is Array(1..Last) of Interfaces.Unsigned_8;
            Function Convert is new Ada.Unchecked_Conversion(
               Source => Object,
               Target => Byte_Sequence
              );
            Function Convert is new Ada.Unchecked_Conversion(
               Source => Byte_Sequence,
               Target => Object
              );

            Input   : Byte_Sequence renames Convert( Item );
        Begin
            Return Result : Constant Object :=
              Convert( Input(Input'Last) & Input(Input'First..Penultiment) );
        End "-";

        Data : Bytes  renames Read_Bytes(Complement);
    Begin
        Return -Make_Readable(  +Populate( Data )  );
    End Init;

    Function Read_Bytes( Input : Interfaces.Unsigned_32 ) return Bytes is
        separate;
  Function Normalize( Item : Object ) return Object is separate;

End  FITS.Checksum;
