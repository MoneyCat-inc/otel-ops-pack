# Contributing to otel-agent-coordination

Thank you for your interest! We welcome contributions.

## Development Setup

```bash
git clone https://github.com/MoneyCat-inc/otel-agent-coordination.git
cd otel-agent-coordination

python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

pip install -e .
pip install -r requirements-dev.txt
```

## Code Style

- Follow PEP 8
- Use type hints
- Document all public functions
- Run: `black .` and `pylint src/`

## Testing

```bash
pytest tests/
```

## Pull Request Process

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes
4. Add tests
5. Update documentation
6. Run tests: `pytest`
7. Submit PR

## Areas We Need Help

- Agent framework integrations (LangChain, CrewAI, AutoGPT)
- Pre-built gate templates
- Performance optimizations
- Documentation
- Example workflows

## Questions?

- Open an issue
- Reach out via Bluesky: @resonai.bsky.social
- Comment on [HN discussion](https://news.ycombinator.com/item?id=46356438)

## Code of Conduct

Be respectful, constructive, and collaborative.
