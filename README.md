# Blawd -- a Bloxsom like Blog Built around Git

    04:24 <@perigrin> .ety blossom
    04:24 <+phenny> "O.E. blostma, from P.Gmc. *blo-s-, from PIE *bhle-, extended 
                    form of *bhel- 'to thrive, bloom.' This is the native word, now 
                    largely superseded by bloom and flower." - 
                    http://etymonline.com/?term=blossom
    04:25 <@perigrin> interesting
    04:25 <@perigrin> .ety flower
    04:25 <+phenny> "c.1200, from O.Fr. flor, from L. florem (nom. flos) 'flower' 
                    (see flora), from PIE base *bhlo- 'to blossom, flourish' (cf. 
                    M.Ir. blath, Welsh blawd 'blossom, flower,' O.E. blowan 'to 
                    flower, bloom')." - http://etymonline.com/?term=flower
    
Blawd is in it's infancy and will hopefully replace MovableType on my own
personal blog one day. The basic idea is to take MultiMarkdown files stored in
a git revisioned tree, combine them with some Template Toolkit templates and
generate a blog. Mostly I'm looking for an excuse to play with Git::PurePerl,
and learn the git internals better.

## Usage

    blawd --directory /path/to/blog --output /path/to/htdocs
    
## TODO

* Make it functional
* Wrap it in an FCGI Handler 
