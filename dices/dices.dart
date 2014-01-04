import 'dart:html';
import 'dart:math';
import 'dart:convert';

import 'package:firebase/firebase.dart';

void main() {
  var f = new Firebase('https://dices.firebaseio.com/users/');
  f.onValue.listen((e) {
    update(e.snapshot.val());
    //print(e.snapshot.ref());
    //print(e.snapshot.hasChildren());
    //print(e.snapshot.val());
  });
}

update(Map objects) {
  Element e = querySelector(".cards");
  e.children.removeWhere((e) => true);
  objects.forEach((k, v) {
    var x = "";
    if (v['dice'] != null) {
      v['dice'].skip(1).forEach((form) {
        var results = JSON.decode(form);
        x += "<p>${new Dice().html(results)}</p>";
      });
    }
    e.appendHtml('<div class="card"><h2>${v['name']}</h2>${markup(v['text'])}<hr>$x</div>');
  });

  querySelectorAll(".card .button").forEach((b) {
    b.onClick.listen((e) => roll(e.target.attributes['data-roll']));
  });
}

String markup(String text) {
  text = text.replaceAll("&", "&amp;");
  text = text.replaceAll("<", "&lt;");
  text = text.replaceAllMapped(new RegExp(r'\[(.*?)\]'), (Match m) => '<a class="button" href="#" data-roll="${m[1]}">${m[1]}</a>');
  return text;
}

roll(String formula) {
  Dice d = new Dice();
  List r = d.roll(formula);
  print(r);
  print(d.sum(r));
  querySelector('.card')..appendHtml(d.html(r))..appendHtml('<br>');
}


class Dice {
  final Random _random = new Random();

  /**
   * Rolls dice according to the following grammar and return the result in a simple to parse
   * list format. Multiple die rolls and/or constants can be added or subtracted. Each die can
   * be rolled multiple times (default is 1) and has any number of sizes (default is 6). `F` is
   * an alias for `d3-2`. `d%` is an alias for `d100`. An uppercase `D` stands for an exploding
   * die, that is if the result is the highest possible value, the die is rolled again.
   *
   *     expr = term {("+" | "-") term}
   *     term = dice | number
   *     dice = [number] ("d" | "D" | "F") [number | "%"]
   *
   *  Returns a list with result descriptions like
   *
   *     ['n', op, const_number]
   *     ['d', op, single_die_roll_result, ...]
   *     ['D', op, [die_roll_result1, ..., die_roll_resultN], ...]
   *     ['F', op, single_die_roll_result, ...]
   */
  List<List> roll(String dice) {
    var results = [];
    var op = 1;
    for (Match m in new RegExp(r'((\d*)([dDF])(\d*|%))|(\d+)|([-+])').allMatches(dice)) {
      if (m[1] != null) {
        bool exploding = m[3] == 'D', fudge = m[3] == 'F';
        int count = int.parse(m[2], onError:(_) => 1);
        int sides = int.parse(m[4], onError:(_) => m[4] == '%' ? 100 : 6);
        var result = [fudge ? 'F' : exploding ? 'D' : 'd', op];
        while (count-- > 0) {
          if (exploding) {
            var dice = [];
            do {
              dice.add(_random.nextInt(sides) + 1);
            } while (dice.last == sides);
            result.add(dice);
          } else if (fudge) {
            result.add(_random.nextInt(3) - 1);
          } else {
            result.add(_random.nextInt(sides) + 1);
          }
        }
        results.add(result);
      } else if (m[5] != null) {
        results.add(['n', op, int.parse(m[5])]);
      } else if (m[6] != null) {
        op = m[6] == '+' ? 1 : -1;
      }
    }
    return results;
  }

  int sum(List<List> results) {
    int sum = 0;
    for (List result in results) {
      if (result[0] == 'D') {
        sum += result.skip(2).fold(0, (sum, e) => sum + e.fold(0, (sum, e) => sum + e)) * result[1];
      } else {
        sum += result.skip(2).fold(0, (sum, e) => sum + e) * result[1];
      }
    }
    return sum;
  }

  String html(List<List> results) {
    var b = new StringBuffer();
    b.write('<span class="die-roll">');
    bool first = true;
    for (List result in results) {
      if (result[0] == 'n') {
        if (result[1] == -1) {
          b.write(' – ');
        } else {
          b.write(' + ');
        }
        b.write(result[2]);
      } else {
        if (result[1] == -1) {
          b.write(' – ');
          if (result.length > 3) {
            b.write('(');
          }
          first = true;
        }
        if (result[0] == 'd') {
          for (int r in result.skip(2)) {
            if (first) {
              first = false;
            } else {
              b.write(' ');
            }
            b.write('<span class="die">$r</span>');
          }
        } else if (result[0] == 'D') {
          for (List rs in result.skip(2)) {
            if (first) {
              first = false;
            } else {
              b.write(' ');
            }
            bool efirst = true;
            for (int r in rs) {
              if (efirst) {
                efirst = false;
              } else {
                b.write('/');
              }
              b.write('<span class="die">$r</span>');
            }
          }
        } else if (result[0] == 'F') {
          for (int r in result.skip(2)) {
            if (first) {
              first = false;
            } else {
              b.write(' ');
            }
            b.write('<span class="die">${"–\u00a0+"[r + 1]}</span>');
          }
        }
        if (result[1] == -1 && result.length > 3) {
          b.write(')');
        }
      }
    }
    b.write('</span>');
    b.write(' = ');
    b.write(sum(results));
    return b.toString();
  }
}
