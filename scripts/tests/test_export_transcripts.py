"""Tests for scripts/export_transcripts.py.

Run with: /usr/bin/python3 -m unittest discover -s scripts/tests -v
"""

import json
import sys
import tempfile
import unittest
from datetime import timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import export_transcripts as et  # noqa: E402

TZ = timezone(timedelta(hours=-4))
HOME = "/Users/tester"
SID = "95eaddbb-7f12-47be-9d46-c317e9113c2a"


def user(ts, content, **extra):
    entry = {
        "type": "user",
        "timestamp": ts,
        "sessionId": SID,
        "version": "2.1.0",
        "message": {"role": "user", "content": content},
    }
    entry.update(extra)
    return entry


def assistant(ts, block, model="claude-opus-5"):
    return {
        "type": "assistant",
        "timestamp": ts,
        "sessionId": SID,
        "version": "2.1.0",
        "message": {"role": "assistant", "model": model, "id": "msg_1", "content": [block]},
    }


def text(value):
    return {"type": "text", "text": value}


def tool_use(name, tool_input, tool_id="toolu_1"):
    return {"type": "tool_use", "id": tool_id, "name": name, "input": tool_input}


def tool_result(ts, content, is_error=False, tool_id="toolu_1"):
    block = {"type": "tool_result", "tool_use_id": tool_id, "content": content, "is_error": is_error}
    return user(ts, [block])


def queued(ts, prompt):
    return {
        "type": "attachment",
        "timestamp": ts,
        "attachment": {"type": "queued_command", "prompt": prompt, "origin": {"kind": "human"}},
    }


START = "2026-09-12T00:41:08.953Z"  # 2026-09-11 20:41:08 -0400
LATER = "2026-09-12T00:54:38.336Z"  # 2026-09-11 20:54:38 -0400


def render(entries):
    return et.render_session(entries, tz=TZ, home=HOME)


class HeaderTests(unittest.TestCase):
    def test_header_lists_session_times_model_and_version(self):
        out = render([user(START, "Hi"), assistant(LATER, text("Hello"))])
        self.assertIn("- **Started:** 2026-09-11 20:41:08 -0400", out)
        self.assertIn("- **Ended:** 2026-09-11 20:54:38 -0400", out)
        self.assertIn(f"- **Session ID:** `{SID}`", out)
        self.assertIn("- **Model:** claude-opus-5", out)
        self.assertIn("- **Claude Code version:** 2.1.0", out)

    def test_header_explains_what_is_omitted(self):
        out = render([user(START, "Hi")])
        self.assertIn("Don't edit by hand", out)
        self.assertIn("reasoning", out)


class HumanTests(unittest.TestCase):
    def test_prompt_is_rendered_with_its_local_time(self):
        out = render([user(START, "Please import the spec.")])
        self.assertIn("### 20:41:08 · Human", out)
        self.assertIn("> Please import the spec.", out)

    def test_multiline_prompt_quotes_every_line(self):
        out = render([user(START, "First line\n\nThird line")])
        self.assertIn("> First line\n>\n> Third line", out)

    def test_prompt_given_as_text_blocks_is_rendered(self):
        out = render([user(START, [text("Block prompt"), {"type": "image", "source": {"data": "QUJD"}}])])
        self.assertIn("> Block prompt", out)
        self.assertIn("[image omitted]", out)
        self.assertNotIn("QUJD", out)

    def test_slash_command_is_rendered_as_a_command(self):
        cmd = "<command-name>/clear</command-name>\n<command-message>clear</command-message>\n<command-args></command-args>"
        out = render([user(START, cmd)])
        self.assertIn("### 20:41:08 · Human", out)
        self.assertIn("> `/clear`", out)
        self.assertNotIn("command-message", out)

    def test_mid_turn_message_is_rendered_as_human(self):
        out = render([user(START, "Start"), queued("2026-09-12T00:43:10.000Z", "Include the screenshots too")])
        self.assertIn("### 20:43:10 · Human (sent mid-turn)", out)
        self.assertIn("> Include the screenshots too", out)

    def test_date_is_shown_when_the_day_changes(self):
        out = render([user(START, "Evening"), user("2026-09-12T04:05:00.000Z", "After midnight")])
        self.assertIn("### 2026-09-12 00:05:00 · Human", out)


class ClaudeTests(unittest.TestCase):
    def test_reply_text_is_rendered_in_full(self):
        reply = "\n".join(f"reply line {i}" for i in range(1, 101))
        out = render([user(START, "Hi"), assistant(LATER, text(reply))])
        self.assertIn("### 20:54:38 · Claude", out)
        self.assertIn("reply line 1\n", out)
        self.assertIn("reply line 100", out)

    def test_bash_call_shows_description_and_command(self):
        call = tool_use("Bash", {"command": "cp a b", "description": "Copy the PDF"})
        out = render([user(START, "Hi"), assistant(LATER, call)])
        self.assertIn("**20:54:38 · Tool call: Bash** — Copy the PDF", out)
        self.assertIn("```sh\ncp a b\n```", out)

    def test_other_tool_call_lists_inputs_and_fences_multiline_values(self):
        call = tool_use("Write", {"file_path": "/repo/spec.md", "content": "line one\nline two"})
        out = render([user(START, "Hi"), assistant(LATER, call)])
        self.assertIn("**20:54:38 · Tool call: Write**", out)
        self.assertIn("- `file_path`: `/repo/spec.md`", out)
        self.assertIn("- `content`:\n\n```\nline one\nline two\n```", out)

    def test_reminder_tags_written_by_the_ai_are_kept(self):
        # The harness injects reminders into prompts and tool results, never into what the AI writes.
        code = 'REMINDER = re.compile(r"<system-reminder>.*?</system-reminder>")'
        call = tool_use("Write", {"file_path": "/repo/x.py", "content": code + "\n"})
        reply = text("Strip `<system-reminder>…</system-reminder>` blocks from results.")
        out = render([user(START, "Hi"), assistant(LATER, call), assistant(LATER, reply)])
        self.assertIn(code, out)
        self.assertIn("Strip `<system-reminder>…</system-reminder>` blocks", out)

    def test_non_string_inputs_are_rendered_as_json(self):
        call = tool_use("Read", {"file_path": "/repo/a", "limit": 30})
        out = render([user(START, "Hi"), assistant(LATER, call)])
        self.assertIn("- `limit`: `30`", out)


class ToolResultTests(unittest.TestCase):
    def test_short_result_is_rendered_whole(self):
        out = render([user(START, "Hi"), tool_result(LATER, "one\ntwo")])
        self.assertIn("**20:54:38 · Tool result**", out)
        self.assertIn("```\none\ntwo\n```", out)
        self.assertNotIn("omitted", out.split("## Transcript", 1)[1])

    def test_long_result_is_cut_after_forty_lines(self):
        body = "\n".join(f"line {i}" for i in range(1, 101))
        out = render([user(START, "Hi"), tool_result(LATER, body)])
        self.assertIn("line 40\n", out)
        self.assertNotIn("line 41", out)
        self.assertIn("_60 more lines omitted._", out)

    def test_error_result_is_labelled(self):
        out = render([user(START, "Hi"), tool_result(LATER, "boom", is_error=True)])
        self.assertIn("**20:54:38 · Tool error**", out)

    def test_image_in_result_becomes_placeholder(self):
        content = [text("PDF read"), {"type": "image", "source": {"type": "base64", "data": "SU1BR0VEQVRB"}}]
        out = render([user(START, "Hi"), tool_result(LATER, content)])
        self.assertIn("PDF read", out)
        self.assertIn("[image omitted]", out)
        self.assertNotIn("SU1BR0VEQVRB", out)

    def test_fence_is_longer_than_any_backtick_run_in_content(self):
        out = render([user(START, "Hi"), tool_result(LATER, "```swift\nlet x = 1\n```")])
        self.assertIn("````\n```swift\nlet x = 1\n```\n````", out)


class RedactionTests(unittest.TestCase):
    def test_email_addresses_are_redacted_everywhere(self):
        out = render(
            [
                user(START, "Mail someone@example.com"),
                tool_result(LATER, "Author: other.person+tag@mail.example.org"),
            ]
        )
        self.assertNotIn("someone@example.com", out)
        self.assertNotIn("other.person+tag@mail.example.org", out)
        self.assertEqual(out.count("[email redacted]"), 2)

    def test_home_directory_becomes_tilde(self):
        out = render([user(START, "Open /Users/tester/Development/x and /Users/tester2/y")])
        self.assertIn("~/Development/x", out)
        self.assertIn("/Users/tester2/y", out)

    def test_system_reminders_are_stripped(self):
        out = render(
            [
                user(START, "Visible<system-reminder>\nhidden context\n</system-reminder>"),
                tool_result(LATER, "ok<system-reminder>more hidden</system-reminder>"),
            ]
        )
        self.assertIn("> Visible", out)
        self.assertIn("ok", out)
        self.assertNotIn("hidden", out)

    def test_message_that_is_only_a_reminder_is_skipped(self):
        out = render([user(START, "Real"), user(LATER, "<system-reminder>only this</system-reminder>")])
        self.assertEqual(out.count("· Human"), 1)


class OmissionTests(unittest.TestCase):
    def test_reasoning_and_harness_entries_are_omitted(self):
        entries = [
            user(START, "Real prompt"),
            assistant(LATER, {"type": "thinking", "thinking": "private musing", "signature": "sig"}),
            {"type": "attachment", "timestamp": LATER, "attachment": {"type": "skill_listing", "content": "SKILLS"}},
            {"type": "mode", "mode": "default"},
            {"type": "system", "subtype": "turn_duration", "timestamp": LATER},
            user(LATER, "<local-command-caveat>Caveat text</local-command-caveat>", isMeta=True),
            user(LATER, "<task-notification>\n<status>completed</status>\n</task-notification>"),
        ]
        out = render(entries)
        for hidden in ("private musing", "SKILLS", "Caveat text", "completed", "turn_duration"):
            self.assertNotIn(hidden, out)
        self.assertEqual(out.count("· Human"), 1)


class OutputNameTests(unittest.TestCase):
    def test_name_uses_local_start_time_and_session_prefix(self):
        name = et.output_name([{"type": "mode"}, user(START, "Hi")], tz=TZ)
        self.assertEqual(name, "2026-09-11-2041-95eaddbb.md")

    def test_default_source_dir_is_derived_from_the_repo_path(self):
        source = et.default_source_dir("/Users/tester/Dev/Half-Life", home=HOME)
        self.assertEqual(source, Path("/Users/tester/.claude/projects/-Users-tester-Dev-Half-Life"))


class ExportTests(unittest.TestCase):
    def write_session(self, directory, name, entries):
        path = Path(directory) / name
        path.write_text("\n".join(json.dumps(e) for e in entries) + "\n")

    def test_export_writes_one_file_per_conversation_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as src, tempfile.TemporaryDirectory() as out:
            self.write_session(src, "a.jsonl", [user(START, "First session")])
            other = user("2026-09-12T01:00:00.000Z", "Second session", sessionId="114a5432-0000")
            self.write_session(src, "b.jsonl", [other])
            self.write_session(src, "empty.jsonl", [{"type": "mode", "mode": "default"}])

            written = et.export(Path(src), Path(out), tz=TZ, home=HOME)

            names = sorted(p.name for p in Path(out).iterdir())
            self.assertEqual(names, ["2026-09-11-2041-95eaddbb.md", "2026-09-11-2100-114a5432.md"])
            self.assertEqual(len(written), 2)
            self.assertEqual(et.export(Path(src), Path(out), tz=TZ, home=HOME), [])

    def test_export_skips_unparseable_lines(self):
        with tempfile.TemporaryDirectory() as src, tempfile.TemporaryDirectory() as out:
            path = Path(src) / "a.jsonl"
            path.write_text(json.dumps(user(START, "Kept")) + "\n{not json\n")
            et.export(Path(src), Path(out), tz=TZ, home=HOME)
            self.assertIn("> Kept", (Path(out) / "2026-09-11-2041-95eaddbb.md").read_text())


if __name__ == "__main__":
    unittest.main()
