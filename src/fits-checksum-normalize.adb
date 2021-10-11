Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
--Pragma Restrictions( No_Implementation_Pragmas               );
-- We need to turn SPARK off for this function.

With
System,
FITS.Checksum;

Separate (FITS.Checksum)
Function Normalize( Item : Object ) return Object
  with SPARK_Mode => Off is
    Procedure Do_Pair(A, B : in out Interfaces.Unsigned_8)
      with Inline, Post => Readable(A) and Readable(B);
    Procedure Do_Index_A( X : in out Object; Index : Index_A )
      with Inline, Post =>
        Readable( X(Index,1) ) and Readable( X(Index,2) ) and
      Readable( X(Index,3) ) and Readable( X(Index,4) );
    --                (For all B in Index_B => Readable(X(Index,B)) );

    Procedure Do_Pair(A, B : in out Interfaces.Unsigned_8) is
    Begin
        loop
            Exit when Readable(A) and Readable(B);
            A:= A + 1;
            --Interfaces.Unsigned_8'Succ( A );
            B:= B - 1;
            --Interfaces.Unsigned_8'Pred( B );
        end loop;
        Pragma Assert( Readable(A) and Readable(B) );
    End Do_Pair;

    Procedure Do_Index_A( X : in out Object; Index : Index_A ) is
    Begin
        Do_Pair( X(Index,1), X(Index,2) );
        Do_Pair( X(Index,3), X(Index,4) );
    End Do_Index_A;

Begin
    Return Result : Object := Item do
        For Index in Result'Range(1) loop
            Do_Index_A( Index => Index, X => Result );
        end loop;
--          Pragma Assert( for all X of Result => Readable(X) );
        Pragma Assume( Readable(Result) );
    end return;
End Normalize;
Pragma Postcondition( Readable(Normalize'Result) );
