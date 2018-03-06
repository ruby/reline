require 'reline'
require 'reline/key_actor'
require 'reline/key_actor/base'

class Reline::KeyActor::Emacs < Reline::KeyActor::Base
  MAPPING = [
    #   0 ^@
    :emacs_set_mark,
    #   1 ^A
    :edit_move_to_beg,
    #   2 ^B
    :edit_prev_char,
    #   3 ^C
    :edit_ignore,
    #   4 ^D
    :emacs_delete_or_list,
    #   5 ^E
    :edit_move_to_end,
    #   6 ^F
    :edit_next_char,
    #   7 ^G
    :edit_unassigned,
    #   8 ^H
    :emacs_delete_prev_char,
    #   9 ^I
    :edit_unassigned,
    #  10 ^J
    :edit_newline,
    #  11 ^K
    :edit_kill_line,
    #  12 ^L
    :edit_clear_screen,
    #  13 ^M
    :edit_newline,
    #  14 ^N
    :edit_next_history,
    #  15 ^O
    :edit_ignore,
    #  16 ^P
    :edit_prev_history,
    #  17 ^Q
    :edit_ignore,
    #  18 ^R
    :edit_redisplay,
    #  19 ^S
    :edit_ignore,
    #  20 ^T
    :edit_transpose_chars,
    #  21 ^U
    :emacs_kill_line,
    #  22 ^V
    :edit_quoted_insert,
    #  23 ^W
    :emacs_kill_region,
    #  24 ^X
    :edit_sequence_lead_in,
    #  25 ^Y
    :emacs_yank,
    #  26 ^Z
    :edit_ignore,
    #  27 ^[
    :emacs_meta_next,
    #  28 ^\
    :edit_ignore,
    #  29 ^]
    :edit_ignore,
    #  30 ^^
    :edit_unassigned,
    #  31 ^_
    :edit_unassigned,
    #  32 SPACE
    :edit_insert,
    #  33 !
    :edit_insert,
    #  34 "
    :edit_insert,
    #  35 #
    :edit_insert,
    #  36 $
    :edit_insert,
    #  37 %
    :edit_insert,
    #  38 &
    :edit_insert,
    #  39 '
    :edit_insert,
    #  40 (
    :edit_insert,
    #  41 )
    :edit_insert,
    #  42 *
    :edit_insert,
    #  43 +
    :edit_insert,
    #  44 ,
    :edit_insert,
    #  45 -
    :edit_insert,
    #  46 .
    :edit_insert,
    #  47 /
    :edit_insert,
    #  48 0
    :edit_digit,
    #  49 1
    :edit_digit,
    #  50 2
    :edit_digit,
    #  51 3
    :edit_digit,
    #  52 4
    :edit_digit,
    #  53 5
    :edit_digit,
    #  54 6
    :edit_digit,
    #  55 7
    :edit_digit,
    #  56 8
    :edit_digit,
    #  57 9
    :edit_digit,
    #  58 :
    :edit_insert,
    #  59 ;
    :edit_insert,
    #  60 <
    :edit_insert,
    #  61 =
    :edit_insert,
    #  62 >
    :edit_insert,
    #  63 ?
    :edit_insert,
    #  64 @
    :edit_insert,
    #  65 A
    :edit_insert,
    #  66 B
    :edit_insert,
    #  67 C
    :edit_insert,
    #  68 D
    :edit_insert,
    #  69 E
    :edit_insert,
    #  70 F
    :edit_insert,
    #  71 G
    :edit_insert,
    #  72 H
    :edit_insert,
    #  73 I
    :edit_insert,
    #  74 J
    :edit_insert,
    #  75 K
    :edit_insert,
    #  76 L
    :edit_insert,
    #  77 M
    :edit_insert,
    #  78 N
    :edit_insert,
    #  79 O
    :edit_insert,
    #  80 P
    :edit_insert,
    #  81 Q
    :edit_insert,
    #  82 R
    :edit_insert,
    #  83 S
    :edit_insert,
    #  84 T
    :edit_insert,
    #  85 U
    :edit_insert,
    #  86 V
    :edit_insert,
    #  87 W
    :edit_insert,
    #  88 X
    :edit_insert,
    #  89 Y
    :edit_insert,
    #  90 Z
    :edit_insert,
    #  91 [
    :edit_insert,
    #  92 \
    :edit_insert,
    #  93 ]
    :edit_insert,
    #  94 ^
    :edit_insert,
    #  95 _
    :edit_insert,
    #  96 `
    :edit_insert,
    #  97 a
    :edit_insert,
    #  98 b
    :edit_insert,
    #  99 c
    :edit_insert,
    # 100 d
    :edit_insert,
    # 101 e
    :edit_insert,
    # 102 f
    :edit_insert,
    # 103 g
    :edit_insert,
    # 104 h
    :edit_insert,
    # 105 i
    :edit_insert,
    # 106 j
    :edit_insert,
    # 107 k
    :edit_insert,
    # 108 l
    :edit_insert,
    # 109 m
    :edit_insert,
    # 110 n
    :edit_insert,
    # 111 o
    :edit_insert,
    # 112 p
    :edit_insert,
    # 113 q
    :edit_insert,
    # 114 r
    :edit_insert,
    # 115 s
    :edit_insert,
    # 116 t
    :edit_insert,
    # 117 u
    :edit_insert,
    # 118 v
    :edit_insert,
    # 119 w
    :edit_insert,
    # 120 x
    :edit_insert,
    # 121 y
    :edit_insert,
    # 122 z
    :edit_insert,
    # 123 {
    :edit_insert,
    # 124 |
    :edit_insert,
    # 125 }
    :edit_insert,
    # 126 ~
    :edit_insert,
    # 127 ^?
    :emacs_delete_prev_char,
    # 128 M-^@
    :edit_unassigned,
    # 129 M-^A
    :edit_unassigned,
    # 130 M-^B
    :edit_unassigned,
    # 131 M-^C
    :edit_unassigned,
    # 132 M-^D
    :edit_unassigned,
    # 133 M-^E
    :edit_unassigned,
    # 134 M-^F
    :edit_unassigned,
    # 135 M-^G
    :edit_unassigned,
    # 136 M-^H
    :edit_delete_prev_word,
    # 137 M-^I
    :edit_unassigned,
    # 138 M-^J
    :edit_unassigned,
    # 139 M-^K
    :edit_unassigned,
    # 140 M-^L
    :edit_clear_screen,
    # 141 M-^M
    :edit_unassigned,
    # 142 M-^N
    :edit_unassigned,
    # 143 M-^O
    :edit_unassigned,
    # 144 M-^P
    :edit_unassigned,
    # 145 M-^Q
    :edit_unassigned,
    # 146 M-^R
    :edit_unassigned,
    # 147 M-^S
    :edit_unassigned,
    # 148 M-^T
    :edit_unassigned,
    # 149 M-^U
    :edit_unassigned,
    # 150 M-^V
    :edit_unassigned,
    # 151 M-^W
    :edit_unassigned,
    # 152 M-^X
    :edit_unassigned,
    # 153 M-^Y
    :edit_unassigned,
    # 154 M-^Z
    :edit_unassigned,
    # 155 M-^[
    :edit_unassigned,
    # 156 M-^\
    :edit_unassigned,
    # 157 M-^]
    :edit_unassigned,
    # 158 M-^^
    :edit_unassigned,
    # 159 M-^_
    :emacs_copy_prev_word,
    # 160 M-SPACE
    :edit_unassigned,
    # 161 M-!
    :edit_unassigned,
    # 162 M-"
    :edit_unassigned,
    # 163 M-#
    :edit_unassigned,
    # 164 M-$
    :edit_unassigned,
    # 165 M-%
    :edit_unassigned,
    # 166 M-&
    :edit_unassigned,
    # 167 M-'
    :edit_unassigned,
    # 168 M-(
    :edit_unassigned,
    # 169 M-)
    :edit_unassigned,
    # 170 M-*
    :edit_unassigned,
    # 171 M-+
    :edit_unassigned,
    # 172 M-,
    :edit_unassigned,
    # 173 M--
    :edit_unassigned,
    # 174 M-.
    :edit_unassigned,
    # 175 M-/
    :edit_unassigned,
    # 176 M-0
    :edit_argument_digit,
    # 177 M-1
    :edit_argument_digit,
    # 178 M-2
    :edit_argument_digit,
    # 179 M-3
    :edit_argument_digit,
    # 180 M-4
    :edit_argument_digit,
    # 181 M-5
    :edit_argument_digit,
    # 182 M-6
    :edit_argument_digit,
    # 183 M-7
    :edit_argument_digit,
    # 184 M-8
    :edit_argument_digit,
    # 185 M-9
    :edit_argument_digit,
    # 186 M-:
    :edit_unassigned,
    # 187 M-;
    :edit_unassigned,
    # 188 M-<
    :edit_unassigned,
    # 189 M-=
    :edit_unassigned,
    # 190 M->
    :edit_unassigned,
    # 191 M-?
    :edit_unassigned,
    # 192 M-@
    :edit_unassigned,
    # 193 M-A
    :edit_unassigned,
    # 194 M-B
    :edit_prev_word,
    # 195 M-C
    :emacs_capitol_case,
    # 196 M-D
    :emacs_delete_next_word,
    # 197 M-E
    :edit_unassigned,
    # 198 M-F
    :emacs_next_word,
    # 199 M-G
    :edit_unassigned,
    # 200 M-H
    :edit_unassigned,
    # 201 M-I
    :edit_unassigned,
    # 202 M-J
    :edit_unassigned,
    # 203 M-K
    :edit_unassigned,
    # 204 M-L
    :emacs_lower_case,
    # 205 M-M
    :edit_unassigned,
    # 206 M-N
    :edit_search_next_history,
    # 207 M-O
    :edit_sequence_lead_in,
    # 208 M-P
    :edit_search_prev_history,
    # 209 M-Q
    :edit_unassigned,
    # 210 M-R
    :edit_unassigned,
    # 211 M-S
    :edit_unassigned,
    # 212 M-T
    :edit_unassigned,
    # 213 M-U
    :emacs_upper_case,
    # 214 M-V
    :edit_unassigned,
    # 215 M-W
    :emacs_copy_region,
    # 216 M-X
    :edit_command,
    # 217 M-Y
    :edit_unassigned,
    # 218 M-Z
    :edit_unassigned,
    # 219 M-[
    :edit_sequence_lead_in,
    # 220 M-\
    :edit_unassigned,
    # 221 M-]
    :edit_unassigned,
    # 222 M-^
    :edit_unassigned,
    # 223 M-_
    :edit_unassigned,
    # 223 M-`
    :edit_unassigned,
    # 224 M-a
    :edit_unassigned,
    # 225 M-b
    :edit_prev_word,
    # 226 M-c
    :emacs_capitol_case,
    # 227 M-d
    :emacs_delete_next_word,
    # 228 M-e
    :edit_unassigned,
    # 229 M-f
    :emacs_next_word,
    # 230 M-g
    :edit_unassigned,
    # 231 M-h
    :edit_unassigned,
    # 232 M-i
    :edit_unassigned,
    # 233 M-j
    :edit_unassigned,
    # 234 M-k
    :edit_unassigned,
    # 235 M-l
    :emacs_lower_case,
    # 236 M-m
    :edit_unassigned,
    # 237 M-n
    :edit_search_next_history,
    # 238 M-o
    :edit_unassigned,
    # 239 M-p
    :edit_search_prev_history,
    # 240 M-q
    :edit_unassigned,
    # 241 M-r
    :edit_unassigned,
    # 242 M-s
    :edit_unassigned,
    # 243 M-t
    :edit_unassigned,
    # 244 M-u
    :emacs_upper_case,
    # 245 M-v
    :edit_unassigned,
    # 246 M-w
    :emacs_copy_region,
    # 247 M-x
    :edit_command,
    # 248 M-y
    :edit_unassigned,
    # 249 M-z
    :edit_unassigned,
    # 250 M-{
    :edit_unassigned,
    # 251 M-|
    :edit_unassigned,
    # 252 M-}
    :edit_unassigned,
    # 253 M-~
    :edit_unassigned,
    # 254	M-^?
    :edit_delete_prev_word
    # 255
    # EOF
  ]
end
