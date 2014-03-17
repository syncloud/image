import sys
from string import Template

def getVariables(parameters):
    replaces={}
    for r in parameters:
        parts = r.split('=')
        key = parts[0]
        value = parts[1]
        replaces[key]=value
    return replaces


if __name__ == '__main__':
    infilename = sys.argv[1]
    outfilename = sys.argv[2]
    
    replaces = getVariables(sys.argv[3:])
    
    infile = open(infilename, 'r')
    lines=infile.readlines()
    infile.close()
    
    outfile = open(outfilename, 'w')
    for line in lines:
        template = Template(line)
        resolved = template.substitute(replaces)
        outfile.write(resolved)
    outfile.close()
        
    
