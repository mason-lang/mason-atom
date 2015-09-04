#! /usr/bin/env node
'use strict'

const
	convertRegexp = _ =>
		// JSON data will store a string representing the regexp
		_ instanceof RegExp ? _.source : _,
	convertCaptures = captures => {
		if (typeof captures === 'string')
			return { 1: { name: captures } }
		else {
			const c = { }
			for (let n in captures)
				c[n] = { name: captures[n] }
			return c
		}
	}
const
	nm = (name, match) => ({ name, match: convertRegexp(match) }),
	nmc = (name, match, captures) => ({
		name,
		match: convertRegexp(match),
		captures: convertCaptures(captures)
	}),
	section = (name, begin, end, opts) => {
		const s = { name, begin: convertRegexp(begin), end: convertRegexp(end) }
		if (opts !== undefined) {
			if (opts.patterns)
				s.patterns = opts.patterns
			if (opts.beginCaptures)
				s.beginCaptures = convertCaptures(opts.beginCaptures)
			if (opts.endCaptures)
				s.endCaptures = convertCaptures(opts.endCaptures)
		}
		return s
	}

const patterns = [ ]

const quotePatterns = [
	nm('constant.character.escape', /\\./),
	nm('variable.interpolation', /\{[^\}]*\}/),
]

for (let i = 0; i < 10; i++)
	// i-indented multi-line quote (begins with i-1 indents, ends with <= i-1 indents)
	patterns.push(section(
		'string',
		`^\\t{${i}}[^\\t"]*"$`,
		`^\\t{,${i}}(?=[^\\t])`,
		{ patterns: quotePatterns }))

patterns.push(
	// one-line quote
	section('string', /"/, /"|(.(?=\n))/, { endCaptures: 'invalid.illegal', patterns: quotePatterns }),

	nm('comment', /\|\s.*/),

	// region
	nmc('entity.name.section', /^\s*(region)[^\n]*\n/, 'comment'),

	// JavaScript reserved word
	nm('invalid.illegal', /(await|enum|implements|interface|package|private|protected|public)\s/),
	// JavaScript keyword
	nm('invalid.illegal', /(arguments|const|delete|eval|instanceof|let|return|typeof|var|void|while)\s/),
	// mason reserved word
	nm('invalid.illegal', /(abstract|await!|final|gen!?|goto!|is|isa|of!?|to|until!?|while!?)\s/),
	// mason keyword
	nm('keyword',
		/(_|->|<~|<~~|and|as|break|built|case|catch|class|cond|debug|debugger|do|else|except|false|@for~?|for|get|if|ignore|in|name|new|not|null|or|out|pass|static|switch|this|true|try|undefined|unless|use|use-debug|with)\s/),
	nm('keyword', /super(\(\)|\s|\.)/),
	nm('keyword.other.special-method', /super!\s/),
	// mason do keyword
	nm('keyword.other.special-method',
		/(assert!|break!|case!|catch!|construct!|do!|except!|finally!|forbid!|for!|if!|set!|switch!|throw!|try!|unless!|use!)\s/),
	// lazy
	nm('keyword', /\~/),

	// bracket
	nm('punctuation.section.embedded', /[\(\[\]\)]/),

	// NumberLiteral
	nmc('constant.numeric', /-?0(b|o|x)[0-9a-f]+/, 'constant.character.escape'),
	nm('constant.numeric', /-?\d+(\.\d+)?/),

	// type test (type *not* in fun or assign)
	nmc('support.type', /(:)\S+/, 'comment'),

	// MemberAccess
	nm('keyword', /\./),

	// action function name
	nm('keyword.other.unit', /[^\.\s]+!/),

	// Function
	section('variable', /(\~?!?\|)/, /\n/, {
		beginCaptures: 'comment',
		patterns: [ nmc('support.type', /(:)\S+/, 'comment'), nm('comment', /#.*/) ]
	}),

	// AssignSingle
	nmc('entity.other.attribute-name', /([^\s\.:]+)((:)([^\s\.]+))?((\.)|\s((=)|(:=|::=)|(<~~?)))\s/, {
		3: 'comment', // : before type
		4: 'support.type', // type
		6: 'comment', // '. '
		8: 'comment', // =
		9: 'entity.name.tag', // := or ::=
		10: 'keyword' // <~ or <~~
	}),

	// focus call
	nmc('constant.language', /\S+(_)/, 'keyword'),

	// reserved character
	nm('invalid.illegal', /[`%^&\\';,]/),

	// LocalAccess (or anything not captured by above)
	nm('none', /[^\s\.\:\(\)\[\]]+/))

const data = {
	name: 'mason',
	scopeName: 'source.mason',
	fileTypes: [ 'ms' ],
	patterns
}

require('fs').writeFileSync('mason.json', JSON.stringify(data, null, '\t'))
