role Hash is EnumMap {
    multi method postcircumfix:<{ }>($key) {
        Q:PIR {
            .local pmc self
            self = find_lex 'self'
            $P0 = getattribute self, '$!storage'
            $P1 = find_lex '$key'
            %r = $P0[$P1]
            unless null %r goto done
            %r = new ['Proxy']
            setattribute %r, '$!base', $P0
            setattribute %r, '$!key', $P1
            $P2 = get_hll_global ['Bool'], 'True'
            setprop %r, 'rw', $P2
          done:
        }
    }

    method !STORE(\$to_store) {
        # We create a new storage hash, in case we are referenced in
        # what is being stored.
        pir::setattribute__vPsP(self, '$!storage', pir::new__Ps('Hash'));

        my $items = $to_store.flat;
        while $items {
            given $items.shift {
                when Enum {
                    self{.key} = .value;
                }
                when EnumMap {
                    for $_.list { self{.key} = .value }
                }
                default {
                    die('Odd number of elements found where hash expected')
                        unless $items;
                    self{$_} = $items.shift;
                }
            }
        }
        self
    }

    method Bool() {
        ?pir::istrue__IP(pir::getattribute__PPs(self, '$!storage'));
    }

    method delete(*@keys) {
        my @deleted;
        for @keys -> $k {
            @deleted.push(self{$k});
            Q:PIR {
                $P0 = find_lex '$k'
                $P1 = find_lex 'self'
                $P1 = getattribute $P1, '$!storage'
                delete $P1[$P0]
            }
        }
        return |@deleted
    }

    method push(*@values) {
        my $previous;
        my $has_previous;
        for @values -> $e {
            if $has_previous {
                self!push_construct($previous, $e);
                $has_previous = 0;
            } elsif $e ~~ Pair {
                self!push_construct($e.key, $e.value);
            } else {
                $previous = $e;
                $has_previous = 1;
            }
        }
        if $has_previous {
            warn "Trailing item in Hash.push";
        }
    }

    # push a value onto a hash Objectitem, constructing an array if necessary
    method !push_construct(Mu $key, Mu $value) {
        if self.exists($key) {
            if self.{$key} ~~ Array {
                self.{$key}.push($value);
            } else {
                self.{$key} = [ self.{$key}, $value];
            }
        } else {
            self.{$key} = $value;
        }
    }

    method list() {
        return self.pairs;
    }

    multi method sort(&by = &infix:<cmp>) {
        self.pairs.sort(&by)
    }

}


