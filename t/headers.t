#!perl6

use v6;

use Test;
use HTTP::Headers;

my (HTTP::Headers $h, HTTP::Headers $h2);

$h = HTTP::Headers.new;
ok($h);
isa_ok($h, "HTTP::Headers");
is($h.as-string, "");

$h .= new;
$h.header('foo') = "bar", "baaaaz", "baz";
is($h.as-string, "Foo: bar\nFoo: baaaaz\nFoo: baz\n");

$h .= new;
$h.header('foo') = ["bar", "baz"];
is($h.as-string, "Foo: bar\nFoo: baz\n");

$h .= new;
$h.header('foo') = 1;
$h.header('bar') = 2;
$h.header('foo-bar') = 3;
is($h.as-string, "Bar: 2\nFoo: 1\nFoo-Bar: 3\n");
is($h.as-string(:eol<;>), "Bar: 2;Foo: 1;Foo-Bar: 3;");

is($h.header("Foo"), 1);
is($h.header("FOO"), 1);
is($h.header("foo"), 1);
is($h.header("foo-bar"), 3);
is($h.header("foo_bar"), 3);
is(?$h.header("Not-There"), False);
is($h.header("Not-There").list, []);

$h.header("Foo") = [ 1, 1 ];
is(~$h.header("Foo"), "1, 1");
is_deeply($h.header("Foo").list, [ 1, 1 ]);
$h.header('foo') = 11;
$h.header('Foo').push: 12; 
$h.header('bar') = 22;
is($h.header("Foo").value, "11, 12");
is($h.header("Bar").value, '22');
$h.header('Bar') = ();
is($h.header("Bar"), '');
$h.header('Bar') = 22;
is($h.header("bar"), '22');
 
$h.header('Bar').push: 22;
is($h.header("Bar"), "22, 22");
$h.header('Bar').push: 23 .. 25;
is($h.header("Bar"), "22, 22, 23, 24, 25");
is($h.header("Bar").list.join('|'), "22|22|23|24|25");

is($h.elems, 3);
$h.clear;
is($h.elems, 0);
$h.header('Foo') = 1;
is($h.as-string, "Foo: 1\n");
$h.header('Foo').init(2);
$h.header('Bar').init(2);
is($h.as-string, "Bar: 2\nFoo: 1\n");
$h.header('Foo').init(2, 3);
$h.header('Baz').init(2, 3);
is($h.as-string, "Bar: 2\nBaz: 2\nBaz: 3\nFoo: 1\n");

is($h.as-string, $h.clone.as-string);
 
is($h.clone.remove-header("Foo"), '1');
is($h.clone.remove-header("Bar"), '2');
is($h.clone.remove-header("Baz"), '2, 3');
is($h.clone.remove-headers(<Foo Bar Baz Not-There>).elems, 4);
is($h.clone.remove-header("Not-There"), HTTP::Header);

$h .= new;
$h.Allow = "GET";
$h.header("Content") = "none";
$h.Content-Type = "text/html";
$h.Content-MD5 = "dummy";
$h.Content-Encoding = "gzip";
$h.header("content_foo") = "bar";
$h.Last-Modified = "yesterday";
$h.Expires = "tomorrow";
$h.ETag = "abc";
$h.Date = "today";
$h.User-Agent = "libwww-perl";
$h.header("zoo") = "foo";
is($h.as-string, q:to/EOT/);
Date: today
User-Agent: libwww-perl
ETag: abc
Allow: GET
Content-Encoding: gzip
Content-MD5: dummy
Content-Type: text/html
Expires: tomorrow
Last-Modified: yesterday
Content: none
Content-Foo: bar
Zoo: foo
EOT

is_deeply([ $h.list».name ], [
    Date, User-Agent, ETag, Allow, Content-Encoding, Content-MD5,
    Content-Type, Expires, Last-Modified, "Content", "Content-Foo",
    "Zoo",
]);

is_deeply([ $h.for-PSGI ], [
    'Date' => 'today',
    'User-Agent' => 'libwww-perl',
    'ETag' => 'abc',
    'Allow' => 'GET',
    'Content-Encoding' => 'gzip',
    'Content-MD5' => 'dummy',
    'Content-Type' => 'text/html',
    'Expires' => 'tomorrow',
    'Last-Modified' => 'yesterday',
    'Content' => 'none',
    'Content-Foo' => 'bar',
    'Zoo' => 'foo',
]);
 
$h2 = $h.clone;
is($h.as-string, $h2.as-string);
isnt($h.WHICH, $h2.WHICH);
isnt($h.headers.WHICH, $h2.headers.WHICH);
 
$h.remove-content-headers;
is($h.as-string, q:to/EOT/);
Date: today
User-Agent: libwww-perl
ETag: abc
Content: none
Zoo: foo
EOT

# Make sure the clone is still the same
is($h2.as-string, q:to/EOT/);
Date: today
User-Agent: libwww-perl
ETag: abc
Allow: GET
Content-Encoding: gzip
Content-MD5: dummy
Content-Type: text/html
Expires: tomorrow
Last-Modified: yesterday
Content: none
Content-Foo: bar
Zoo: foo
EOT

$h2.remove-content-headers;
is($h.as-string, $h2.as-string);
 
$h.clear;
is($h.as-string, "");
$h2 = Nil;

# Headers may be set to date or instants and do TheRightThing™
my $date = DateTime.new(:2015year, :5month, :14day, :9hour, :48minute);
$h.Date = $date;
is($h.as-string, "Date: Thu, 14 May 2015 09:48:00 GMT\n");
$h.Date = Instant.new(1431596915);
is($h.as-string, "Date: Thu, 14 May 2015 09:48:00 GMT\n");
$h.Retry-After = Duration.new(120);
is($h.as-string, "Date: Thu, 14 May 2015 09:48:00 GMT\nRetry-After: 120\n");

$h.clear;
$h.Content-Type = 'text/html; charset=UTF-8';
is($h.Content-Type.primary, 'text/html');
is($h.Content-Type.charset, 'UTF-8');
$h.Content-Type.charset = 'ISO-8859-1';
is(~$h.Content-Type, 'text/html; charset=ISO-8859-1');
$h.Content-Type.charset = Nil;
is(~$h.Content-Type, 'text/html');
$h.Content-Type.charset = 'Latin1';
is(~$h.Content-Type, 'text/html; charset=Latin1');
is($h.Content-Type.is-html, True);
is($h.Content-Type.is-text, True);
is($h.Content-Type.is-xhtml, False);
is($h.Content-Type.is-xml, False);

# Test the Hash-accessors
is($h{Content-Type}.name, Content-Type);
is($h<Content-Type>.name, Content-Type);

$h<Zoo> = 'bar';
is($h<Zoo>.name, 'Zoo');
is($h<Zoo>.value, 'bar');

is($h<Zoo> :exists, True);
ok($h<Zoo> :delete);
is($h<Zoo> :exists, False);

# Apps may choose to extend with their own headers
class MyApp::CustomHeaders is HTTP::Headers {
    enum MyAppHeader < X-Foo X-Bar >;

    method build-header($name, *@values) {
        if $name ~~ MyAppHeader {
            HTTP::Header::Custom.new(:name($name.Str), :42values);
        }
        else {
            nextsame;
        }
    }

    multi method header(MyAppHeader $name) is rw {
        self.header-proxy($name);
    }

    method X-Foo is rw { self.header(MyAppHeader::X-Foo) }
    method X-Bar is rw { self.header(MyAppHeader::X-Bar) }
}

my $h3 = MyApp::CustomHeaders.new;
is($h3.X-Foo.value, 42);
is($h3.X-Bar.value, 42);
is($h3.as-string(:eol('; ')), "X-Bar: 42; X-Foo: 42; ");

done;
