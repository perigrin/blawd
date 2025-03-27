# BlawdNexus Template Directory

This directory contains the templates used by BlawdNexus for rendering content.

## Directory Structure

The template files are organized in the `templates/` subdirectory, following the Module::Build::Tiny convention for shared files.

When the module is installed, these templates will be installed to the distribution's sharedir, where they can be accessed using File::ShareDir::Tiny.

## Template Files

The templates use Text::Template syntax with `.tmpl` extension. Key templates include:

- `layout.tmpl` - The main layout template
- `entry.tmpl` - For rendering individual entries
- `index.tmpl` - For rendering index pages
- `archive.tmpl` - For rendering archive pages
- `tag.tmpl` - For rendering tag pages

## Custom Templates

You can override these templates by configuring a custom templates directory in your configuration file:

```yaml
templates:
  directory: /path/to/your/templates
```

When a custom templates directory is configured, it will take precedence over the shared templates.