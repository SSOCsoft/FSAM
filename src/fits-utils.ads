Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
Pragma Restrictions( No_Implementation_Pragmas               );

Private Package FITS.Utils with Pure, SPARK_Mode => On is
    Space : Character renames Header_Character_First;

    -- Returns the input, less the leading occourances of Ch.
    Function Left_Trim( S : String; Ch : Character:= Space ) return String
      with Post => (if Left_Trim'Result'Length in Positive
                      then Left_Trim'Result(Left_Trim'Result'First) /= Ch);

    -- Returns the input, less the trailing occourances of Ch.
    Function Right_Trim( S : String; Ch : Character:= Space ) return String
      with Post => (if Right_Trim'Result'Length in Positive
                      then Right_Trim'Result(Right_Trim'Result'Last) /= Ch);

    -- Returns the input, less the leading and trailing occourances of Ch.
    Function Trim( S : String; Ch : Character:= Space ) return String
      with Post => (if Trim'Result'Length in Positive
                      then Trim'Result(Trim'Result'First) /= Ch
                       and Trim'Result(Trim'Result'Last ) /= Ch  );

    -- Returns the position of Ch within S, or 0 if it is not found.
    Function Index( S : String; Ch : Character ) return Natural
      with Post => (if Index'Result in Positive
                      then S(Index'Result) = Ch
                       and (for all C of S(S'First..Positive'Pred(Index'Result))
                             => C /= Ch)
                   );

    -- Returns the number of occourances of Ch within S.
    Function Count( S : String; Ch : Character ) return Natural
      with Post => (if Index(S,Ch) not in Positive then Count'Result = 0
                    else  Count'Result in 1..S'Length-Index(S,Ch));

    -- Apply a character-mapping function to he given string.
    Generic
        with Function Map(Ch : Character) return Character;
    Function Do_Map( S : String ) return String;


End FITS.Utils;
