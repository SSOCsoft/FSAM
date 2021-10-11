Pragma Ada_2012;
Pragma Assertion_Policy( Check );
Pragma Restrictions( No_Implementation_Aspect_Specifications );
Pragma Restrictions( No_Implementation_Attributes            );
Pragma Restrictions( No_Implementation_Pragmas               );

With
Interfaces;

Package FITS.Checksum with Pure, SPARK_Mode => On is


    -- The Checksum object.
    Type Object is private
      with Size => 32 * 4;

    Function Init( X : Interfaces.Unsigned_32 ) return Object;
    Function Print(Item : Object) return Record_String;

PRIVATE
    Type Index_A is (A, B, C, D);
    Type Index_B is range 1..4;

    Function Readable( Item : Object ) return Boolean with Inline;
    Type Object is Array(Index_A, Index_B) of Interfaces.Unsigned_8
      with --TYPE_INVARIANT => Readable( Object ),
           --Type invarients not implemented in this version of SPARK.
        Convention => Fortran;

    use Interfaces;
    subtype Checksum_String is String(1..16);
    subtype Readable_Character is Checksum_Character
      with Static_Predicate => Readable_Character in '0'..'9'|'A'..'Z'|'a'..'z';


    Function As_String(Item : Object) return Record_String
      with Inline, Pre => Readable(Item),
      Post => (for all C of As_String'Result => C in Readable_Character);

    Function Print(Item : Object) return Record_String is
      (''' & As_String( Item ) & ''');

    Function Readable( Item : Interfaces.Unsigned_8 ) Return Boolean is
        ( Character'Val(Item) in Readable_Character ) with Inline;
    Function Readable( Item : Object ) return Boolean is
        (for all C of Item => Readable(C));
--        (for all X in Item'Range(1) =>
--             (  for all Y in Item'Range(2) => Readable(Item(X,Y))  )
--        );
End  FITS.Checksum;
