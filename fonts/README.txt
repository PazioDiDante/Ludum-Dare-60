Edit Undo bitmap fonts

The PNG and YY files together define the HTML5 fonts at sizes 16, 18 and 24.
They contain the original Edit Undo artwork and glyph advances, rather than a
request to regenerate glyphs from a locally installed system font.

Keep maintainGms1Font=true, canGenerateBitmap=false and regenerateBitmap=false
on these cached resources. The legacy bitmap preservation setting is intentional.
Regenerating a missing font with a substitute replaces the glyph artwork and
metrics even if the resource name still says Edit Undo.

For an intentional font change, regenerate from the supplied original TTF in
datafiles/fonts/edit-undo, and verify the resulting PNG before exporting HTML5.
After external resource changes, reload the project in GameMaker so it reads
the current resources from disk instead of retaining an older editor copy.
