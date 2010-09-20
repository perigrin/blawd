# Blawd -- a Jekyll/Bloxsom like Blog Built around Git

Blawd is a blog aware git based content management system, similar to
Bloxsom or Jekyll. It has managed to replace MovableType on my personal
blog, but it is still very very rough. By default it will generate a
tree of HTML documents, but it can be run as a server as well using
[Plack](http://search.cpan.org/dist/Plack).

## The Name

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

## Usage

    blawd server --repo /path/to/blog.git 

