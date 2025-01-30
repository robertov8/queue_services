# QueueServices


# QueueServices

QueueServices é uma implementação de fila usando GenServer em Elixir, permitindo operações assíncronas de enfileiramento e desenfileiramento de elementos.

## Iniciar a fila manualmente (não recomendado por ser já implementado no Application)

```elixir
{:ok, pid} = QueueServices.QueueGenServer.start_link([])
```

## Enfileirar elementos

```elixir
QueueServices.QueueGenServer.enqueue("primeiro")
QueueServices.QueueGenServer.enqueue("segundo")
QueueServices.QueueGenServer.enqueue("terceiro")
QueueServices.QueueGenServer.enqueue(["quarto", "quinto"])
```

## TODO

- [ ] Implementar desenfileiramento de fila
- [ ] Implementar testes
