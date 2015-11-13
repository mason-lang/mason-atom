import
	fs writeFileSync
	mason-compile.dist.info keywords reservedKeywords
	msl.dist.Object map-object-values

replace-many = |str regexp-source replacer
	str.replace (new RegExp regexp-source 'g) replacer

r = |strings ...values
	| Gets a raw string.
	s = String.raw strings ...values
	|| Template strings have to escape ` characters, but don't need that in the regexp.
	s2 = replace-many s "\\\\`" "`"
	|| Same for " characters
	replace-many s2 "\\\\\\\"" "\""

convert-captures = |case
	:String
		todo SYNTAX (name. _)
		"1".
			name. _
	else
		map-object-values _ |capture-class
			name. capture-class

nm = |-name match
	name. -name
	match.
nmc = |-name match captures
	name. -name
	match.
	'captures. convert-captures captures
section = |-name begin end opts
	name. -name
	begin.
	end.
	if opts.patterns
		patterns. opts.patterns
	if opts.beginCaptures
		beginCaptures. convert-captures opts.beginCaptures
	if opts.endCaptures
		endCaptures. convert-captures opts.endCaptures

non-id-characters = r"\s.:()\[\]\"&"
rgx-break = "[{non-id-characters}]"
rgx-id = "[^{non-id-characters}]+"

patterns =
	quote-patterns =
		. nm "constant.character.escape" r"\\."
		. nm "variable.interpolation" r"\{[^\}]*\}"

	for i of 0..9
		begin = "^\\t\{{i}}[^\\t\"]*\"$"
		end = "^\\t\{,{i}}(?=[^\\t])"
		. section 'string begin end (patterns. quote-patterns)

	|| one-line quote
	. section 'string "\"" r"\"|(.(?=\n))" (endCaptures. "invalid.illegal" patterns. quote-patterns)

	|| simple quote
	. nm 'string "\'{rgx-id}"

	. nm 'comment r"\|(\||\s).*"

	|| region
	. nmc "entity.name.section" r"^\s*(region)[^\n]*\n" 'comment
	|| todo
	. nmc "entity.name.section" r"^\s*(todo)[^\n]*\n" 'comment

	. nm "invalid.illegal" r"({=> String reservedKeywords "|"})(?={rgx-break})"
	|| mason keyword
	remaining-keywords = (@keep keywords &(not (new RegExp "[|=.:*]").test_))
	|| <-* must be added in with escaping
	. nm 'keyword r"({=> String remaining-keywords "|"}|<-\*)(?={rgx-break})"
	. nm 'keyword "~"

	|| bracket
	. nm "punctuation.section.embedded" r"[\(\[\]\)]"

	|| NumberLiteral
	. nmc "constant.numeric" r"-?0(b|o|x)[0-9a-f]+" "constant.character.escape"
	. nm "constant.numeric" r"-?\d+(\.\d+)?"

	|| type test (type *not* in fun or assign)
	. nmc "support.type" r"(:)\S+" 'comment

	|| MemberAccess
	. nm 'keyword r"\."

	|| Function
	. section 'variable r"((\*|\$)?!?\|)" r"\n"
		beginCaptures. 'comment
		patterns.
			. nmc "support.type" r"(:)\S+" 'comment
			. nm 'comment r"\|\s.*"
	. nm "support.type" "&"

	|| AssignSingle
	. nmc "entity.other.attribute-name" r"([^\s\.:]+)((:)([^\s\.]+))?((\.)|\s((=)|(:=|::=)|(<~~?)))\s"
		"3". 'comment || : before type
		"4". "support.type" || type
		"6". 'comment || '. '
		"8". 'comment || =
		"9". "entity.name.tag" || := or ::=
		"10". 'keyword || <~ or <~~

	|| reserved character
	. nm "invalid.illegal" r"[`#%^\\';,]"

	|| focus call
	. nmc "constant.language" r"{rgx-id}(_)" 'keyword

	|| LocalAccess (or anything not captured by above)
	. nm 'none r"{rgx-id}"

writeFileSync "mason.json"
	content =
		name. 'mason
		scopeName. "source.mason"
		fileTypes. ['ms]
		patterns.
	JSON.stringify content null "\t"
