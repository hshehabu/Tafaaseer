import unittest

from tafaseer_pipeline.mushaf import LINES_PER_PAGE, Word, build_lines


def words_for(layout):
    """layout: [(ayah_id, page, line), ...] one word each, in mushaf order."""
    return [Word(i, a, p, n, False, f"w{i}") for i, (a, p, n) in enumerate(layout, start=1)]


class BuildLinesTests(unittest.TestCase):
    def test_titles_and_bismillahs_fill_the_empty_lines(self):
        # Surah 1 (ayahs 1-2) fills page 1 from line 2 and all of page 2. Surah 2 (ayah 3) starts on page 3
        # after its title and bismillah. Surah 3 (ayah 4) starts on page 4 line 1: its title and
        # bismillah close page 3.
        layout = [(1, 1, 2), (2, 1, 3)] + [(2, 2, n) for n in range(1, LINES_PER_PAGE + 1)]
        layout += [(3, 3, n) for n in range(3, LINES_PER_PAGE - 1)]
        layout += [(4, 4, n) for n in range(1, LINES_PER_PAGE + 1)]
        lines = build_lines(words_for(layout), {1: 1, 2: 3, 3: 4})
        kinds = [(l.page, l.line, l.kind, l.surah) for l in lines if l.kind != "ayah"]
        self.assertEqual(kinds, [(1, 1, "surah", 1), (3, 1, "surah", 2), (3, 2, "basmala", 2),
                                 (3, 14, "surah", 3), (3, 15, "basmala", 3)])
        self.assertEqual(len([l for l in lines if l.page == 1]), 3)  # opening page is short

    def test_surah_9_has_no_bismillah(self):
        def layout(first_line):
            return [(1, 1, 2)] + [(2, 2, n) for n in range(first_line, LINES_PER_PAGE + 1)]

        lines = build_lines(words_for(layout(2)), {1: 1, 9: 2})
        self.assertEqual([l.kind for l in lines if l.surah == 9], ["surah"])
        with self.assertRaises(ValueError):  # two empty lines before surah 9: one is unexplained
            build_lines(words_for(layout(3)), {1: 1, 9: 2})

    def test_unexplained_empty_line_fails(self):
        layout = [(1, 1, 2), (1, 2, 1), (1, 2, 3)]
        with self.assertRaises(ValueError):
            build_lines(words_for(layout), {1: 1})
