# Blawd -- a Jekyll/Bloxsom like Blog Built around Git

Blawd is a blog aware git based content management system, similar to
Bloxsom or Jekyll. It has managed to replace MovableType on my personal
blog, but it is still very very rough. By default it will generate a
tree of HTML documents, but it can be run as a server as well using
[HTTP::Engine](http://search.cpan.org/dist/HTTP-Engine).

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

    blawd server --directory /path/to/blog.git 

## Coverage
<pre>
---------------------------- ------ ------ ------ ------ ------ ------ ------
File                           stmt   bran   cond    sub    pod   time  total
---------------------------- ------ ------ ------ ------ ------ ------ ------
lib/Blawd.pm                  100.0  100.0    n/a  100.0  100.0    6.5  100.0
lib/Blawd/Entry/API.pm        100.0    n/a    n/a  100.0    n/a    0.1  100.0
...wd/Entry/MultiMarkdown.pm   74.4    0.0   50.0   66.7  100.0    2.7   64.7
lib/Blawd/Index.pm            100.0   50.0    n/a  100.0  100.0    3.7   97.2
lib/Blawd/Renderable.pm       100.0    n/a    n/a  100.0  100.0    1.1  100.0
lib/Blawd/Renderer/API.pm     100.0    n/a    n/a  100.0    n/a    0.1  100.0
...Renderer/MultiMarkdown.pm  100.0    n/a    n/a  100.0  100.0    2.9  100.0
lib/Blawd/Renderer/RSS.pm     100.0    n/a    n/a  100.0  100.0    1.4  100.0
lib/Blawd/Storage/API.pm      100.0    n/a    n/a  100.0  100.0    1.1  100.0
lib/Blawd/Storage/Git.pm      100.0    n/a  100.0  100.0  100.0   26.9  100.0
t/01.simple.t                 100.0    n/a    n/a  100.0    n/a   24.3  100.0
t/02.git-wrap.t                98.6    n/a    n/a  100.0    n/a   25.3   98.7
t/03.multi-markdown.t          97.1    n/a    n/a  100.0    n/a    3.9   97.6
Total                          97.0   30.0   62.5   96.3  100.0  100.0   95.3
---------------------------- ------ ------ ------ ------ ------ ------ ------
</pre>