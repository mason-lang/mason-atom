[mason](http://mason-lang.org) syntax for [atom](https://atom.io).

Install
===

	git clone https://github.com/mason-lang/mason-atom.git
	cd mason-atom
	apm link .

Files with the `.ms` extension should now be highlighted.

(You can't just do `apm install mason-lang/mason-atom`.
See the [issue](https://github.com/atom/apm/issues/355).)


Build
===

	npm install
	cd grammars
	mason run generate.ms
