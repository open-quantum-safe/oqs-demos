import yaml
from jinja2 import Environment, FileSystemLoader

with open("generate.yml", "r") as file:
    data = yaml.safe_load(file)

env = Environment(loader=FileSystemLoader("."))
template = env.get_template("qsc_template.jinja2")

output = template.render(data=data)

with open("qsc.h", "w") as output_file:
    output_file.write(output)

print("qsc.h has been successfully generated!")