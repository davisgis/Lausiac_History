(:  NAME: DH_Class_Geo_Machine_Reading.xquery
    AUTHOR: Anthony Davis, with assistance from Dr. Cliff Anderson
    BEGIN DATE:  3/17/2014
    SUMMARY:  XQuery with two inputs: 1) TEI Collection (Syriaca.org Gazetteer), and; 2) Stanford CoreNLP Text (Lausiac History).
    The query iterates through a sequence of sentences from the text document, then iterates through the place collection replacing
    each matched place in the text document with the corresponding place in the Gazetteer.  It returns a TEI/XML file with the matched 
    locations marked in a TEI <placeName> element with an @URI attribute.
    INITIALS: AD:  Anthony Davis; CA:  Dr. Cliff Anderson
    NOTES:
    20130317:   AD-  original query returned a sequence of places and sentences, but returned a sentence for each place.  
    20140319:   CA-  suggested the use of user defined functions and use of the intersection function:  http://www.xqueryfunctions.com/xq/functx_value-intersect.html
    20140322:   AD-  added user defined functions: local:match-place, local:create-places; 
                added logic to functx:value-intersect()intersect and functx:value-except()
    20140406:   AD-  tweaked query to run for Lausiac History
    :)
   
xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";

(: 20130322: AD- A functx function from http://www.xqueryfunctions.com/xq/functx_value-intersect.html :)
declare function functx:value-intersect
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values($arg1[.=$arg2])
 } ;
 
(: 20140322: AD- A functx function from http://www.xqueryfunctions.com/xq/functx_value-except.html :)
declare function functx:value-except
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values($arg1[not(.=$arg2)])
 } ;

(: 20140322: AD- created local function :)
declare function local:match-place($places as xs:string*, $sentence as element()?)   as item()*
    {
    (:  1) Find placeNames from Geographic Data (Syriaca.org) in the Text (Chronicle of Edessa)
        2) then replace with TEI information <placeName ref= URI>{place}</placeName> :)
        
         let $sentence-text := fn:string-join($sentence//word, " ") 
         for $place-string in $places
         let $place := substring-before($place-string , "--")
         let $id := substring-after($place-string, "place-")
         (: ******TESTING ONLY******
         where $place = "Edessa" :)
         
        return
         fn:replace($sentence-text, $place, concat("<placeName ref=", "'http://syriaca.org/place/", $id ,  "'>",  $place , "</placeName>"), "s") 
    };
    
(: 20140322: AD- created local function :)
declare function local:create-places($geo) as item()*
    {
     (: 1) Grab Place data in Syriaca.org for georeferencing (PlaceName, URI),
        2) Concat the data together and return as a string  :)
    
    for $places in $geo
    let $place-name := ($places//tei:place/tei:placeName[1])/text()
    let $id := string($places//ancestor::tei:place/@xml:id)
    let $place := concat($place-name, "--", $id)
    return $place
    };


    (: 201403017: AD- Input Geographic Data: Syriaca.org Gazetteer :)
    let $geo := fn:collection("/db/apps/srophe/data/places/tei")
    
    (: 201403017: AD- Input Matching Text Data: Chronicle of Edessa :)
    let $input := fn:doc("/db/Lausiac/Data/lausiac_input.txt.xml")
    
    let $TEI :=
    (: 201403021: AD- Iterate through each sentence in Matching Text Data:  Chronicle of Edessa :)
    for $sentence in $input/root/document/sentences/sentence
    return  ("<p>",(if ((functx:value-except(local:match-place(local:create-places($geo), $sentence) ,fn:string-join($sentence//word, " ") )) != "") 
                then (functx:value-except(local:match-place(local:create-places($geo), $sentence) ,fn:string-join($sentence//word, " ") ))
                else functx:value-intersect(local:match-place(local:create-places($geo), $sentence),fn:string-join($sentence//word, " "))) , "</p>")

     (: 201403022: AD- Added TEI Namespace and Header :)  
     return ("<TEI xmlns='http://www.tei-c.org/ns/1.0' xmlns:math='http://www.w3.org/1998/Math/MathML' xmlns:xi='http://www.w3.org/2001/XInclude' xmlns:svg='http://www.w3.org/2000/svg' xml:lang='en'>
    <teiHeader>
        <fileDesc>
            <titleStmt>
        <title>Palladius, The Lausiac History (1918) pp. 35-180. English Translation.</title>
    </titleStmt>
        <publicationStmt>
            <publisher>Anthony Davis</publisher>
        </publicationStmt>
            <sourceDesc>
                <bibl>http://www.tertullian.org/fathers/palladius_lausiac_02_text.htm</bibl>
            </sourceDesc>
    </fileDesc>
    </teiHeader>
    <text>
        <body>
            <div>", $TEI, "</div>
        </body>
    </text>
</TEI>")