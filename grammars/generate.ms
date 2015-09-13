use
	global JSON
	fs writeFileSync
	msl.dist.Object map-object-values Map->Object

replace-many = |str regexp-source replacer
	str.replace (new RegExp regexp-source "g") replacer

| Gets a raw string.
r = |strings ...values
	s = String.raw strings ...values
	| Template strings have to escape ` characters, but don't need that in the regexp.
	s2 = replace-many s "\\\\`" "`"
	| Same for " characters
	replace-many s2 "\\\\\\\"" "\""

convert-captures = |case
	:String
		| TODO:SYNTAX `"1". (name. _)`
		Map->Object
			"1" ->
				name. _
	else
		map-object-values _ |capture-class
			name. capture-class

| TODO:SYNTAX Object literals that use outer variables
nm = |-name -match
	name. -name
	match. -match
nmc = |-name -match -captures
	name. -name
	match. -match
	captures. convert-captures -captures
section = |-name -begin -end opts
	name. -name
	begin. -begin
	end. -end
	if! opts.patterns
		patterns. opts.patterns
	if! opts.beginCaptures
		beginCaptures. convert-captures opts.beginCaptures
	if! opts.endCaptures
		endCaptures. convert-captures opts.endCaptures

-patterns =
	quote-patterns =
		. nm "constant.character.escape" r"\\."
		. nm "variable.interpolation" r"\{[^\}]*\}"

	for! i in new Range 0 10
		begin = "^\\t\{{i}}[^\\t\"]*\"$"
		end = "^\\t\{,{i}}(?=[^\\t])"
		. section "string" begin end (patterns. quote-patterns)

	| one-line quote
	. section "string" "\"" r"\"|(.(?=\n))" (endCaptures. "invalid.illegal" patterns. quote-patterns)

	. nm "comment" r"\|\s.*"

	| region
	. nmc "entity.name.section" r"^\s*(region)[^\n]*\n" "comment"

	| JavaScript reserved word
	. nm "invalid.illegal" r"(await|enum|implements|interface|package|private|protected|public)\s"
	| JavaScript keyword
	. nm "invalid.illegal" r"(arguments|const|delete|eval|instanceof|let|return|typeof|var|void|while)\s"
	| mason reserved word
	. nm "invalid.illegal" r"(abstract|await!|export|final|gen!?|goto!|is|isa|of!?|to|until!?|while!?)\s"
	| mason keyword
	. nm "keyword"
		r"(_|->|<~|<~~|and|as|break|built|case|catch|class|cond|debug|debugger|do|else|except|false|@for~?|for|get|if|ignore|import|import-debug|in|name|new|not|null|or|out|pass|static|switch|this|true|try|undefined|unless|with)\s"
	. nm "keyword" r"super(\(\)|\s|\.)"
	. nm "keyword.other.special-method" r"super!\s"
	| mason do keyword
	. nm "keyword.other.special-method"
		r"(assert!|break!|case!|catch!|construct!|do!|except!|finally!|forbid!|for!|if!|set!|switch!|throw!|try!|unless!|use!)\s"
	. nm "keyword" "~"

	| bracket
	. nm "punctuation.section.embedded" r"[\(\[\]\)]"

	| NumberLiteral
	. nmc "constant.numeric" r"-?0(b|o|x)[0-9a-f]+" "constant.character.escape"
	. nm "constant.numeric" r"-?\d+(\.\d+)?"

	| type test (type *not* in fun or assign)
	. nmc "support.type" r"(:)\S+" "comment"

	| MemberAccess
	. nm "keyword" r"\."

	| Function
	. section "variable" r"(\~?!?\|)" r"\n"
		beginCaptures. "comment"
		patterns.
			. nmc "support.type" r"(:)\S+" "comment"
			. nm "comment" r"\|\s.*"

	| AssignSingle
	. nmc "entity.other.attribute-name" r"([^\s\.:]+)((:)([^\s\.]+))?((\.)|\s((=)|(:=|::=)|(<~~?)))\s" (Map->Object
		| TODO:SYNTAX `"3". "comment" and so on
		"3" -> "comment" | : before type
		"4" -> "support.type" | type
		"6" -> "comment" | '. '
		"8" -> "comment" | =
		"9" -> "entity.name.tag" | := or ::=
		"10" -> "keyword" | <~ or <~~

	| reserved character
	. nm "invalid.illegal" r"[`#%^&\\';,]"

	| focus call
	. nmc "constant.language" r"[^\s\.\:\(\)\[\]\"]+(_)" "keyword"

	| LocalAccess (or anything not captured by above)
	. nm "none" r"[^\s\.\:\(\)\[\]\"]+"

writeFileSync "mason.json"
	data =
		name. "mason"
		scopeName. "source.mason"
		fileTypes. ["ms"]
		patterns. -patterns
	JSON.stringify data null "\t"
