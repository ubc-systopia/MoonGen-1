#include <deque>
#include <cstdint>

extern "C" {

struct deque_entry {
    uint8_t key[16];
    uint8_t timestamp[8];
};

std::deque<deque_entry> *deque_create() {
    return new std::deque<deque_entry>();
}

struct deque_entry deque_peek_back(std::deque<deque_entry> *queue) {
    return queue->back();
}

void deque_remove_back(std::deque<deque_entry> *queue) {
    queue->pop_back();
}

void deque_push_front(std::deque<deque_entry> *queue, struct deque_entry entry) {
    queue->push_front(entry);
}

bool deque_empty(std::deque<deque_entry> *queue){
    return queue->empty();
}

}