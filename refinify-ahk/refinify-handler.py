import os
import base64
import sys
import json
import argparse
from openai import AzureOpenAI
import logging
from dotenv import load_dotenv, dotenv_values

load_dotenv()

def setup_logger():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    log_path = os.path.join(script_dir, "refinify-handler.log")
    logging.basicConfig(
        filename=log_path,
        filemode='a',
        format='%(asctime)s %(levelname)s: %(message)s',
        level=logging.DEBUG
    )
    return logging.getLogger("refinify")

logger = setup_logger()

###############################################################################

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input-file', dest='input_file', type=str, default=None)
    parser.add_argument('--output-file', dest='output_file', type=str, default=None)
    parser.add_argument('message', nargs='?', default=None)
    return parser.parse_args()

def get_user_message(args):
    if args.input_file:
        with open(args.input_file, 'r', encoding='utf-8') as f:
            return f.read().strip()
    if args.message:
        return args.message.strip()
    user_message = sys.stdin.read()
    if len(user_message) == 0:
        raise ValueError("No message provided.")
    return user_message.strip()

def get_secret_from_envfile(filepath, key):
    return dotenv_values(filepath).get(key)

def init_openai():
    OPENAI_ENDPOINT_URL = "https://jfs-ai-use2.openai.azure.com"
    OPENAI_API_VERSION = "2025-01-01-preview"
    secrets_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env-secrets")
    OPENAI_SUBSCRIPTION_KEY = dotenv_values(secrets_file).get("AZURE_OPENAI_API_KEY")
    if not OPENAI_SUBSCRIPTION_KEY:
        raise RuntimeError("AZURE_OPENAI_API_KEY is not found in {secrets_file} file")
    logger.debug(f"OpenAI Endpoint: {OPENAI_ENDPOINT_URL}, API Version: {OPENAI_API_VERSION}")
    return AzureOpenAI(
        azure_endpoint=OPENAI_ENDPOINT_URL,
        api_key=OPENAI_SUBSCRIPTION_KEY,
        api_version=OPENAI_API_VERSION,
    )

def build_prompt(user_message):
    prompt_text = (
        "You are a helpful assistant. Your task is to improve my messages to make them more concise, clear, and professional. "
        "Keep the original meaning, any specific formatting or styling, and preserve my tone—including jokes or sarcasm if present. "
        "However, if anything could sound rude or impolite, please rephrase it to be more polite. "
        "Do not use complicated English or complex sentences. "
        "Assume the audience is often highly technical, but not always. "
        "Both I and my audience are usually not native English speakers, so keep the language simple and direct."
    )
    return [
        {
            "role": "system",
            "content": [
                {
                    "type": "text",
                    "text": prompt_text
                }
            ]
        },
        {
            "role": "user",
            "content": user_message
        }
    ]
    logger.debug(f"Chat prompt: {chat_prompt}")

def build_completions(openai_client, chat_prompt):
    return openai_client.chat.completions.create(
        model="gpt-4.1",
        messages=chat_prompt,
        max_tokens=800,
        temperature=0.7,
        top_p=0.95,
        frequency_penalty=0,
        presence_penalty=0,
        stop=None,
        stream=False
    )

def to_ascii_equivalents(text):
    # Basic replacement for common smart quotes, dashes, ellipsis, etc.
    replacements = {
        '\u2018': "'", '\u2019': "'",  # single quotes
        '\u201c': '"', '\u201d': '"',  # double quotes
        '\u2013': '-', '\u2014': '-',   # dashes
        '\u2026': '...',                # ellipsis
        '\u00a0': ' ',                  # non-breaking space
        '\u2012': '-', '\u2015': '-',  # more dashes
        '\u2212': '-',                  # minus sign
        '\u00b7': '-',                  # middle dot
        '\u2022': '-',                  # bullet
        '\u2122': '(TM)',               # trademark
        '\u00ae': '(R)',                # registered
        '\u00a9': '(C)',                # copyright
    }
    for uni, ascii_ in replacements.items():
        text = text.replace(uni, ascii_)
    return text.encode('ascii', errors='replace').decode('ascii')

def refine_message(completions):
    logger.debug(f"Completion JSON: {json.dumps(json.loads(completions.to_json()), indent=2)}")
    refined_message = completions.choices[0].message.content
    cleaned_message = to_ascii_equivalents(refined_message)
    return cleaned_message.strip()

def save_output(args, message):
    if not args.output_file:
        return
    logger.debug(f"Saving output to: {args.output_file}")
    with open(args.output_file, 'w', encoding='utf-8') as f:
        f.write(message)

def main():
    logger.debug("Script started")
    args = parse_args()
    user_message    = get_user_message(args)
    openai_client   = init_openai()
    chat_prompt     = build_prompt(user_message)
    completions     = build_completions(openai_client, chat_prompt)
    message         = refine_message(completions)
    save_output(args, message)
    logger.info(f"Original message: {user_message}\nFinal message: {message}")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.error(f"An error occurred: {e}", exc_info=True)
        sys.exit(1)
