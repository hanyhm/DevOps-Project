const supertest = require("supertest");
const app = require("../app");
const Movie = require("../models/movie");
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

const request = supertest(app);
const endpoint = "/api/movies";

let mongoServer;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();

  await mongoose.connect(uri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });
});

afterAll(async () => {
  await mongoose.connection.close();
  await mongoServer.stop();
});

describe(endpoint, () => {

  describe("GET /", () => {
    it("should return all movies", async () => {
      const titles = ["m1", "m2"];
      const movies = titles.map((title) => ({
        title,
      }));
      await Movie.insertMany(movies);

      const res = await request.get(endpoint);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBeTruthy();
      titles.forEach((title) =>
        expect(res.body.some((m) => m.title === title)).toBeTruthy()
      );

      await Movie.deleteMany({ title: { $in: titles } });
    });
  });

  describe("POST /", () => {
    it("should return 400 if request is not valid", async () => {
      const res = await request.post(endpoint).send({});

      expect(res.status).toBe(400);
    });

    it("should store the movie and return 201 if request is valid", async () => {
      const movie = { title: "m" };

      const res = await request.post(endpoint).send(movie);

      expect(res.status).toBe(201);
      expect(res.body.title).toBe(movie.title);
      expect(res.body._id).toBeTruthy();

      await Movie.findByIdAndDelete(res.body._id);
    });
  });

  const request = supertest(app);
  const endpoint = "/api/movies";
  

});
