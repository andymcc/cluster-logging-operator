package generators

import (
	"bytes"
	"fmt"
	"text/template"
)

//Generator is a template engine
type Generator struct {
	*template.Template
}

//New creates an instance of a template engine for a set of templates
func New(name string, addFunctions *template.FuncMap, templates ...string) (*Generator, error) {
	allFunctions := funcMap
	if addFunctions != nil {
		for name, f := range *addFunctions {
			allFunctions[name] = f
		}
	}
	tmpl := template.New(name).Funcs(funcMap)
	var err error
	for i, s := range templates {
		tmpl, err = tmpl.Parse(s)
		if err != nil {
			return nil, fmt.Errorf("Error parsing %q template %v: %s", name, i, err)
		}
	}
	return &Generator{tmpl}, nil
}

//Execute the named template using the given data
func (gen *Generator) Execute(namedTemplate string, data interface{}) (string, error) {
	var out bytes.Buffer
	if err := gen.Template.ExecuteTemplate(&out, namedTemplate, data); err != nil {
		return "", fmt.Errorf("Error processing template %s: %v", gen.Template.Name(), err)
	}
	return out.String(), nil
}