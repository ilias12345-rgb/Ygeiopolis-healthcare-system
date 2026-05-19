from ui import render_app


def main() -> None:
    # Streamlit entrypoint; page routing and database screens live in ui.py.
    render_app()


if __name__ == "__main__":
    main()
