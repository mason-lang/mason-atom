import
	fs writeFileSync
	mason-compile.lib.info keywords reservedKeywords
	msl.lib.Object map-object-values

convert-captures = \case
	:Str
		todo SYNTAX (name. _)
		"1".
			name. _
	else
		todo SYNTAX &(name. _)
		map-object-values _ \capture-class
			name. capture-class

nm = \-name:Str match:RegExp
	name. -name
	'match. match.source

nmc = \-name:Str match:RegExp captures
	name. -name
	'match. match.source
	'captures. convert-captures captures

section = \-name:Str begin:RegExp end:RegExp opts:Object
	name. -name
	'begin. begin.source
	'end. end.source
	if opts.patterns
		patterns. opts.patterns
	if opts.beginCaptures
		beginCaptures. convert-captures opts.beginCaptures
	if opts.endCaptures
		endCaptures. convert-captures opts.endCaptures

todo get from info (see bottom of chars.js)
non-id-characters = "`&()\\[\\]{}|:\".\\s\#^\\\\;,'"
|| non-id-characters = "\\s.:()\\[\\]\"&"
rgx-break-ahead = `(?=[#non-id-characters])`
rgx-id = `[^#non-id-characters]+`

patterns =
	quote-patterns =
		. nm "constant.character.escape" `\\.`
		. nmc 'comment `\#(#rgx-id)` "support.type"
		. nmc 'comment `\#\(([^\)]*)\)` "support.type"

	for i of 0..9
		begin = `^\t{#i}[^\t"]*"$`
		end = `^\t{,#i}(?=[^\t])`
		. section 'string begin end (patterns. quote-patterns)

	|| regexp
	. section 'string `\`` `\`(g?i?m?y?)|(.(?=\n))`
		endCaptures.
			"2". "invalid.illegal"
		patterns. quote-patterns

	|| one-line quote
	. section 'string `"` `"|(.(?=\n))` (endCaptures. "invalid.illegal" patterns. quote-patterns)

	|| simple quote
	. nm 'string `'#rgx-id`

	. nm 'comment `\|(\||\s).*`

	|| region
	. nm 'comment `^\s*(region)[^\n]*\n`
	|| todo
	. nmc 'comment `^\s*(todo)[^\n]*\n` 'keyword

	|| bracket
	. nm "punctuation.section.embedded" `[\(\[\]\)]`

	|| NumberLiteral
	. nmc "constant.numeric" `-?0(b|o|x)[0-9a-f]+` "constant.character.escape"
	. nm "constant.numeric" `-?\d+(\.\d+)?`

	|| type test (type *not* in fun or assign)
	. nmc "support.type" `(:)[^\s=]+` 'comment

	|| MemberAccess
	. nm 'keyword `\.`

	|| Function
	. section 'variable `((\*|\$)?\!?\\)` `\n`
		beginCaptures. 'comment
		patterns.
			. nmc "support.type" `(:)\S+` 'comment
			. nm 'comment `\|\s.*`
	. nm "support.type" `&`

	|| AssignSingle
	. nmc "entity.other.attribute-name" `([^\s\.:]+)((:)([^\s\.]+))?((\.)|\s(=))\s`
		"3". 'comment || : before type
		"4". "support.type" || type
		"6". 'comment || '. '
		"7". 'comment || =

	|| reserved character
	. nm "invalid.illegal" `[\#^\\';,]`

	|| focus call
	. nmc "constant.language" `#rgx-id(_)` 'keyword

	. nm "invalid.illegal" `(#(=> String reservedKeywords "|"))#rgx-break-ahead`
	escaped-keywords = @for k of keywords
		unless `[|=.:]`.test k
			. pipe k
				_.replace `\$`g "\\$"
				_.replace `\+`g "\\+"
				_.replace `\*`g "\\*"
				_.replace `\?`g "\\?"

	|| `this` isn't implemented as a keyword but should be highlighted.
	extra-keywords = `this|==?\?|<=\?|>=\?|:=`
	. nm 'keyword `(#(=> String escaped-keywords "|")|#extra-keywords)#rgx-break-ahead`
	. nm 'keyword `~`

	|| LocalAccess (or anything not captured by above)
	. nm 'none rgx-id

writeFileSync "mason.json"
	content =
		name. 'mason
		scopeName. "source.mason"
		fileTypes. ['ms]
		patterns.
	JSON.stringify content null "\t"
