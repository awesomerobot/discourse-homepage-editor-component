import Component from "@glimmer/component";
import AsyncResult from "./async-result";

// Base class for blocks that fetch data asynchronously and want to avoid
// refetching when unrelated state changes (e.g. another block being edited).
//
// Subclasses must implement:
//   get fetchKey()   — string that changes only when a refetch is needed
//   fetchData()      — returns a Promise of the data to render
export default class CachedAsyncBlock extends Component {
  _cachedKey;
  _cachedData;

  get loadedData() {
    const key = this.fetchKey;
    if (key !== this._cachedKey) {
      this._cachedKey = key;
      this._cachedData = new AsyncResult(this.fetchData());
    }
    return this._cachedData;
  }
}
