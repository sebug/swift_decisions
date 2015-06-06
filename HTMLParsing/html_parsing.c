#include <stdio.h>
#include <gumbo.h>

void parseHTML() {
  GumboOutput* output = gumbo_parse("<h1>Hello, World!</h1>");
  gumbo_destroy_output(&kGumboDefaultOptions, output);
}

void getInput(int* output) {
  scanf("%i", output);
}
