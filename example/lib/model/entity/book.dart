class Book{
  String name;
  String content;

  Book(this.name, this.content);

  @override
  String toString() {
    return 'Book{name: $name, content: $content}';
  }
}