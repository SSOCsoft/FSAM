Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
Pragma Restrictions( No_Implementation_Pragmas               );

Package Body FITS.Utils with SPARK_Mode => On is
    Function Left_Trim( S : String; Ch : Character:= Space ) return String is
      (if S'Length not in Positive then ""
       elsif S(S'First) /= Ch then S
       else Left_Trim( S(Positive'Succ(S'First)..S'Last), Ch )
      );

    Function Right_Trim( S : String; Ch : Character:= Space ) return String is
      (if S'Length not in Positive then ""
       elsif S(S'Last) /= Ch then S
       else Right_Trim( S(S'First..Positive'Pred(S'Last)), Ch )
      );

    Function Trim( S : String; Ch : Character:= Space ) return String is
      ( Left_Trim( Right_Trim(S, Ch), Ch ) );

    Function Index( S : String; Ch : Character ) return Natural is
    Begin
        Return Result : Natural := 0 do
            Search:
            For Index in S'Range loop
                if S(Index) = Ch then
                    Result:= Index;
                    Exit Search;
                End If;
            End Loop Search;
        End return;
    End Index;


    Function Count( S : String; Ch : Character ) return Natural is
    Begin
        Return Result : Natural := Natural'First do
            Scan:
            For C of S loop
                if C = Ch then
                    Result:= Natural'Succ( Result );
                End If;
            End Loop Scan;
        End return;
    End Count;

    Function Do_Map( S : String ) return String is
    Begin
        Return Result : String := S do
            For I in Result'Range loop
                Result(I):= Map( Result(I) );
            end loop;
        End return;
    End Do_Map;



End FITS.Utils;
