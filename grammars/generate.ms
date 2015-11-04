import
	global JSON
	fs writeFileSync
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
	"captures". convert-captures captures
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

rgx-id =
	| Regex for an identifier.
	r"[^\s\.\:\(\)\[\]\"&]+"

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

	|| JavaScript reserved word
	. nm "invalid.illegal" r"(await|enum|implements|interface|package|private|protected|public)\s"
	|| JavaScript keyword
	. nm "invalid.illegal" r"(arguments|const|delete|eval|in|instanceof|let|return|typeof|var|void|while)\s"
	|| mason reserved word
	. nm "invalid.illegal" r"(abstract|await!|export|final|gen!?|goto!|is|meta|out|to|until!?|while!?)\s"
	|| mason keyword
	keywords = "
		_ -> <~ <~~ and as assert break built case catch class cond construct debug debugger del do
		else except false finally @for~? for forbid get if ignore import!? import-debug kind name
		new not null of or pass set static switch this throw true try undefined unless with
	. nm 'keyword r"({replace-many keywords "\\s" "|"})\s"
	. nm 'keyword r"super(\(\)|\s|\.)"
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
	. section 'variable r"((\~|\$)?!?\|)" r"\n"
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
